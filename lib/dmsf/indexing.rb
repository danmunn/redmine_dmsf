module Dmsf
  # TODO:
  #   The longer plan (probably Dmsf 1.6.0 will be to support different indexing strategies)
  #   right now we include the getIndexer to retrieve said instance, however of itself
  #   Dmsf::Indexing would ultimately become a module, and then strategies would exist as child
  #   namespaces, to be loaded via configuration - There could be options to support ferret as
  #   an optional replacement to Xapian or other live equivilents.

  class Indexing
    class XapianLibraryError < RuntimeError; end

    # Retrieves a copy of instantiated Dmsf::Indexing
    # There is no point having lots of copies of this class about
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - +Dmsf::Indexing+ -> Instance of Dmsf::Indexing
    #
    def self.getIndexer
      return @@indexer unless @@indexer.nil?
      @@indexer = new Dmsf::Indexing()
    end

    # Determines if Indexing (Xapian) is available
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - +Boolean+ -> Available (true); Unavailable (false)
    #
    def indexer_available?
      begin
        require 'xapian'
        return true
      rescue LoadError
        return false
      end
    end

    # Sets the index file location
    #
    # * *Args*    :
    #   - +value+ -> Location of index file
    # * *Returns* :
    #   - None
    #
    def set_index= value
      @index = value
    end

    # Gets the index file location
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - +String+ -> Location of index file
    #
    def get_index
      location = @index
      location ||= (Setting.plugin_redmine_dmsf["dmsf_index_database"].strip)
      return location
    end

    def query_index(query, opts = {})
      raise self.XapianLibraryError unless indexer_available?
      options = {
        :lang      => 'en',
        :stemming  => 'STEM_NONE',
        :all_words => true,
      }.merge!(opts)

      xapian = Xapian::Enquire.new(get_index)
      stemmer = Xapian::Stem.new(options[:lang])
      query_parse = Xapian::QueryParser.new()
      query_parse.stemmer = stemmer;query_parse.database = xapian
      case opts[:stemming].string
        when 'STEM_NONE' then query_parse.stemming_strategy = Xapian::QueryParser::STEM_NONE
        when 'STEM_SOME' then query_parse.stemming_strategy = Xapian::QueryParser::STEM_SOME
        when 'STEM_ALL'  then query_parse.stemming_strategy = Xapian::QueryParser::STEM_ALL
      end
      query_parse.default_op = options[:all_words] ? Xapian::Query::OP_AND : Xapian::Query::OP_OR
      xapian.query = query_parse.parse_query(query)
      return xapian.mset(0,1000 )
    end


  end
end