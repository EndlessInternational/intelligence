module Intelligence
  ##
  # The +Tool+ class instance encpasulates a definition of a tool that may be executed by a 
  # model. The properies of a tool include a unique name, a comprehensive description of what 
  # the tool does and a set of properies that describe the arguments the tool accepts, each 
  # with its own type and validation rules.
  #
  # A +Tool+ instance does not implement the tool, only the defintion of the tool, which is 
  # presented to the model to allow it to make a tool call.
  #
  # == Configuration 
  #
  # A tool MUST include the +name+ and +description+ and may include any number of 
  # +arguments+ as well as a +required+ attribute with a list of the required arguments. 
  # Each argument must include a +name+ and may include +description+, +type+, a list of 
  # acceptable values through +enum+ and a +minimum+ and +maximum+ for numerical 
  # arguments. 
  #
  # === Tool Attributes   
  #
  # - +name+: A +String+ representing the unique name of the tool. *required*
  # - +description+: A +String+ describing it's purpose and functionality. *required*
  #
  # === Argument Attributes
  #
  # An argument is defined through the +argument+ block. The block MUST include the +name+,
  # while all other attributes, including the +description+ and +type+ are all optional.
  #
  # - +type+: 
  #   A +String+ indicating the data type of the property. Accepted values include +string+, 
  #   +number+, +integer+, +array+, +boolean+, +object+. 
  # - +name+: A +String+ representing the name of the property. *required*
  # - +description+: A +String+ that describes the property and its purpose. *required*
  # - +minimum+: An +Integer+ or +Float+ specifying the minimum value for numerical properties.
  # - +maximum+: An +Integer+ or +Float+ specifying the maximum value for numerical properties.
  # - +enum+: 
  #   An +Array+ of acceptable values for the property. Note that ( as per the JSON schema 
  #   specification ) an enum could be composed of mixed types but this is discouraged. 
  # - +required: 
  #   A boolean ( +TrueClass+, +FalseClass+ ) that specifying if the argument is required.
  #
  # === Examples
  #
  # weather_tool = Tool.build! do 
  #   name :get_weather_by_locality
  #   description \ 
  #     "The get_weather_by_locality tool will return the current weather in a given locality " \
  #     "( city, state or province, and country )."
  #   argument name: 'city', type: 'string', required: true do 
  #     description "The city or town for which the current weather should be returned."
  #   end 
  #   argument name: 'state', type: 'string' do 
  #     description \
  #       "The state or province for which the current weather should be returned. If this is " \
  #       "not provided the largest or most prominent city with the given name, in the given " \
  #       "country, will be assumed."
  #   end  
  #   argument name: 'country', type: 'string', required: true do 
  #     description "The city or town for which the current weather should be returned."
  #   end 
  # end
  #
  # web_browser_tool = Tool.build! 
  #   name :get_web_page
  #   description "The get_web_page tool will return the content of a web page, given a page url."
  #   argument name: :url, type: 'string', required: true do 
  #     description \
  #       "The url of the page including the scheme.\n"
  #       "Examples:\n"
  #       "  https://example.com\n"
  #       "  https://www.iana.org/help/example-domains\n"
  #   end 
  #   argument name: :format do
  #     description \
  #       "The format of the returned content. By default you will receive 'markdown'. You " \
  #       "should specify 'html' only if it is specifically required to fullfill the user " \
  #       "request." 
  #     enum [ 'html', 'markdown' ] 
  #   end 
  #   argument name: :content do
  #     description \
  #       "The content of the page to be returned. By default you will receive only the 'main' " \
  #       "content, excluding header, footer, menu, advertising and other miscelanous elements. " \
  #       "You should request 'full' only if absolutely neccessry to fullfill the user request. " \
  #     enum [ 'main', 'full' ]
  #   end 
  #   argument name: :include_tags do
  #     description "If content is set to html some tags will."
  #   end 
  # end 
  # 
  class Tool
    include DynamicSchema::Definable
    include DynamicSchema::Buildable

    ARGUMENT_TYPES = [ 'string', 'number', 'integer', 'array', 'boolean', 'object' ]

    ARGUMENT_SCHEMA = proc do
      type            String, in: ARGUMENT_TYPES
      name            String, required: true
      description     String, required: true 
      required        [ TrueClass, FalseClass ]
      # note that an enum does not require a type as it implicitly restricts the argument 
      # to specific values
      enum            array: true 
      # for arguments of type number and integer
      minimum         [ Integer, Float ]
      maximum         [ Integer, Float ]
      # for arguments of type array 
      maximum_items   Integer, as: :maxItems
      minimum_items   Integer, as: :minItems 
      unique_items    [ TrueClass, FalseClass ]
      items           do
        type          in: ARGUMENT_TYPES
        property      array: true, as: :properties, &ARGUMENT_SCHEMA 
      end
      # for arguments of type object 
      property        array: true, as: :properties, &ARGUMENT_SCHEMA
    end

    schema            do 
      name            String, required: true 
      description     String, required: true 
      argument        array: true, as: :properties do 
        self.instance_eval( &ARGUMENT_SCHEMA )
      end 
    end  
    
    def initialize( attributes = nil )
      @properties = attributes
    end 

    def to_h
      @properties.to_h
    end 

  end
end

