require 'spec_helper'
require 'debug'
require 'dentaku'

RSpec.shared_examples 'stream requests with calculator tool' do | options = {} |

  def calculator( arguments )
    if arguments.is_a?( String )
      begin
        arguments = JSON.parse( arguments )
      rescue 
        raise RuntimeError, 
              "The parameter format is not valid, it should be \"{expression: '2+2'}\"." 
      end
    end

    arguments = arguments.transform_keys( &:to_sym )
    expression = arguments.fetch( :expression ) do
      raise RuntimeError, "The parameter must include an `expression`."
    end

    calculator = Dentaku::Calculator.new
    calculator.store( { pi: Math::PI, e: Math::E } )

    calculator.evaluate!( expression )
  end

  let ( :get_calculator_tool ) {
    Intelligence::Tool.build! do
     name 'calculator'
      description \
        "# Calculator\n" \
        "The claculator DSL evaluates math, comparisons, logic, and numeric aggregates.\n" \
        "## Numbers\n" \
        "- Integers and floats are accepted.\n" \
        "- Bitwise operators use integers; non-integers are truncated.\n" \
        "- The result of bitwise operators are non-numeric but can be converted to numeric using ROUND.\n" \
        "## Arithmetic operators\n" \
        "- + (add), - (subtract), * (multiply), / (divide), % (modulo), ^ (power).\n" \
        "- Bitwise: | (or), & (and), << (shift left), >> (shift right).\n" \
        "## Math Functions\n" \
        "- SIN, COS, TAN, ASIN, ACOS, ATAN, ATAN2, SINH, COSH, TANH, ASINH, ACOSH, ATANH, " \
        "  SQRT, EXP, LOG, LOG10, POW.\n" \
        "- Angles are in radians.\n" \
        "## Comparison Operators\n" \
        "- =, !=, <>, <, >, <=, >= return booleans.\n" \
        "## Logical functions\n" \
        "- IF(cond, then, else).\n" \
        "- AND(a, b, ...), OR(a, b, ...), XOR(a, b), NOT(x).\n" \
        "- XOR(a, b) is true if exactly one argument is true.\n" \
        "## Numeric Functions\n" \
        "- MIN(...), MAX(...), SUM(...), AVG(...), COUNT(...).\n" \
        "- ROUND(x, [digits]).\n" \
        "- ROUNDDOWN(x, [digits]) rounds toward zero.\n" \
        "- ROUNDUP(x, [digits]) rounds away from zero.\n" \
        "- ABS(x).\n" \
        "## Constants\n" \
        "- PI, E" \
        "## Aggregates\n" \
        "- Functions accept a list of values or an array, e.g., SUM(1,2,3) or\n" \
        "  SUM(1,2,3).\n" \
        "- COUNT counts non-nil numeric arguments.\n" \
        "## Operator precedence (high to low)\n" \
        "1) Parentheses and functions\n" \
        "2) Unary +, unary -, NOT\n" \
        "3) ^\n" \
        "4) *, /, %\n" \
        "5) +, -\n" \
        "6) <<, >>\n" \
        "7) &\n" \
        "8) |\n" \
        "9) Comparisons (=, !=, <>, <, >, <=, >=)\n" \
        "10) AND, XOR, OR\n" \
        "## Errors and Edge Cases\n" \
        "- Division by zero raises an error.\n" \
        "- Non-numeric values in numeric functions raise an error.\n" \
        "- Mismatched list sizes in INTERCEPT raise an error.\n" \

      argument name: :expression, type: 'string', required: true do
        description \
          "Formula to evaluate. Examples: \n"\
          "- 1 + 2 * 3 -> 7\n" \
          "- ^ is power: 2 ^ 3 -> 8\n" \
          "- Bitwise: 5 | 2 -> 7, 5 & 2 -> 0, 5 << 1 -> 10\n" \
          "- Trig: SIN(PI/2) -> 1\n" \
          "- IF(2 > 1, 10, 0) -> 10\n" \
          "- ROUND(3.14159, 2) -> 3.14; ROUNDUP(-1.2) -> -1; ROUNDDOWN(1.9) -> 1\n" \
          "- AVG(1,2,3,4) -> 2.5\n" \
      end
    end
  }

  context 'where there is a conversation about mathematical questions' do 

    context 'which requires the calculator tool to complete' do
      it 'streams the appropriate generated text' do

        response = nil
        conversation = Intelligence::Conversation.build do 
          system_message do 
            content text: "You are a helpfull assistant who answers questions succinctly. " +
                          "Please use the calculator tool when asked mathematical questions."
          end
          message role: :user do 
            content text: 'What is 3 * 5?'
          end 
        end 

        response = create_and_make_stream_request( 
          send( options[ :adapter ] || :adapter ), 
          conversation, 
          tools: [ get_calculator_tool ]
        )
        
        expect( response.success? ).to be( true ), response_error_description( response )
        expect( response.result ).to be_a( Intelligence::ChatResult )
        expect( response.result.choices ).not_to be_nil
        expect( response.result.choices.length ).to eq( 1 )
        expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

        choice = response.result.choices.first
        expect( choice.end_reason ).to eq( :tool_called  )
        expect( choice.message ).to be_a( Intelligence::Message )
        message = choice.message
        expect( message.contents ).not_to be_nil
        expect( message.contents.length ).to be > 0
        expect( message.contents.last ).to be_a( Intelligence::MessageContent::ToolCall )
       
        tool_call = message.contents.last
        expect( tool_call.tool_name ).to eq( 'calculator' )

        value = calculator( tool_call.tool_parameters )
        expect( value ).not_to be_nil

        conversation << message
        conversation << Intelligence::Message.build! do 
          role :user
          content do
            type :tool_result
            tool_name tool_call.tool_name
            tool_call_id tool_call.tool_call_id
            tool_result value
          end
        end

        response = create_and_make_stream_request( 
          send( options[ :adapter ] || :adapter ), 
          conversation, 
          tools: [ get_calculator_tool ]
        )

        expect( response.success? ).to be( true ), response_error_description( response )
        expect( response.result ).to be_a( Intelligence::ChatResult )
        expect( response.result.choices ).not_to be_nil
        expect( response.result.choices.length ).to eq( 1 )
        expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

        choice = response.result.choices.first
        expect( choice.end_reason ).to eq( :ended  )
        expect( choice.message ).to be_a( Intelligence::Message )
        expect( choice.message.contents ).not_to be_nil
        expect( choice.message.contents.length ).to be > 0
        expect( choice.message.contents.last ).to be_a( Intelligence::MessageContent::Text )
        expect( choice.message.contents.last.text ).to match( /15/i )

      end
    end
  end 

end
