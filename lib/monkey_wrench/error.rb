module MonkeyWrench
  class Error < StandardError
    attr_reader :code

    def initialize(message, code, extra_fields = {}) 
      super(message)
      @code = code
      @extra_fields = extra_fields
    end

    def type
      types[@code]
    end

    def method_missing(sym, *args, &block)
      return @extra_fields[sym.to_s] if @extra_fields.has_key?(sym.to_s)
    end
    
    def types
      {
        -32601 => 'ServerError_MethodUnknown',
        -32602 => 'ServerError_InvalidParameters',
        -99 => 'Unknown_Exception',
        -98 => 'Request_TimedOut',
        -92 => 'Zend_Uri_Exception',
        -91 => 'PDOException',
        -91 => 'Avesta_Db_Exception',
        -90 => 'XML_RPC2_Exception',
        -90 => 'XML_RPC2_FaultException',
        -50 => 'Too_Many_Connections',
        0 => 'Parse_Exception',
        100 => 'User_Unknown',
        101 => 'User_Disabled',
        102 => 'User_DoesNotExist',
        103 => 'User_NotApproved',
        104 => 'Invalid_ApiKey',
        105 => 'User_UnderMaintenance',
        120 => 'User_InvalidAction',
        121 => 'User_MissingEmail',
        122 => 'User_CannotSendCampaign',
        123 => 'User_MissingModuleOutbox',
        124 => 'User_ModuleAlreadyPurchased',
        125 => 'User_ModuleNotPurchased',
        126 => 'User_NotEnoughCredit',
        127 => 'MC_InvalidPayment',
        200 => 'List_DoesNotExist',
        210 => 'List_InvalidInterestFieldType',
        211 => 'List_InvalidOption',
        212 => 'List_InvalidUnsubMember',
        213 => 'List_InvalidBounceMember',
        214 => 'List_AlreadySubscribed',
        215 => 'List_NotSubscribed',
        220 => 'List_InvalidImport',
        221 => 'MC_PastedList_Duplicate',
        222 => 'MC_PastedList_InvalidImport',
        230 => 'Email_AlreadySubscribed',
        231 => 'Email_AlreadyUnsubscribed',
        232 => 'Email_NotExists',
        233 => 'Email_NotSubscribed',
        250 => 'List_MergeFieldRequired',
        251 => 'List_CannotRemoveEmailMerge',
        252 => 'List_Merge_InvalidMergeID',
        253 => 'List_TooManyMergeFields',
        254 => 'List_InvalidMergeField',
        270 => 'List_InvalidInterestGroup',
        271 => 'List_TooManyInterestGroups',
        300 => 'Campaign_DoesNotExist',
        301 => 'Campaign_StatsNotAvailable',
        310 => 'Campaign_InvalidAbsplit',
        311 => 'Campaign_InvalidContent',
        312 => 'Campaign_InvalidOption',
        313 => 'Campaign_InvalidStatus',
        314 => 'Campaign_NotSaved',
        315 => 'Campaign_InvalidSegment',
        316 => 'Campaign_InvalidRss',
        317 => 'Campaign_InvalidAuto',
        318 => 'MC_ContentImport_InvalidArchive',
        330 => 'Invalid_EcommOrder',
        350 => 'Absplit_UnknownError',
        351 => 'Absplit_UnknownSplitTest',
        352 => 'Absplit_UnknownTestType',
        353 => 'Absplit_UnknownWaitUnit',
        354 => 'Absplit_UnknownWinnerType',
        355 => 'Absplit_WinnerNotSelected',
        500 => 'Invalid_Analytics',
        501 => 'Invalid_DateTime',
        502 => 'Invalid_Email',
        503 => 'Invalid_SendType',
        504 => 'Invalid_Template',
        505 => 'Invalid_TrackingOptions',
        506 => 'Invalid_Options',
        507 => 'Invalid_Folder',
        508 => 'Invalid_URL',
        550 => 'Module_Unknown',
        551 => 'MonthlyPlan_Unknown',
        552 => 'Order_TypeUnknown',
        553 => 'Invalid_PagingLimit',
        554 => 'Invalid_PagingStart'
      }
    end
  end
end

 
