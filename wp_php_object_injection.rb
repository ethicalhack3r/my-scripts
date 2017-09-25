java_import 'burp.IBurpExtender'
java_import 'burp.IScannerCheck'
java_import 'burp.IScanIssue'

require 'java'
java_import 'java.util.Arrays'
java_import 'java.util.ArrayList'

#
# You will need to download JRuby's Complete.jar file from http://jruby.org/download and configure Burp Extender with its path.
# You will also need to install the WordPress PHP Object Injection WordPress Plugin created by White Fir Design.
# Tip: Remove "PHP object injection has occurred." from the WordPress PHP Object Injection WordPress Plugin's description to not cause a false positive.
#
# Inspiration/idea and WordPress Plugin from https://www.pluginvulnerabilities.com/2017/07/24/wordpress-plugin-for-use-in-testing-for-php-object-injection/
# Burp Extension code from https://raw.githubusercontent.com/PortSwigger/example-scanner-checks/master/ruby/CustomScannerChecks.rb
#

GREP_STRING = 'PHP object injection has occurred.'
GREP_STRING_BYTES = GREP_STRING.bytes.to_a
INJ_TEST = 'O:20:"PHP_Object_Injection":0:{}'.bytes.to_a
INJ_ERROR = 'PHP object injection has occurred.'
INJ_ERROR_BYTES = INJ_ERROR.bytes.to_a

class BurpExtender
  include IBurpExtender, IScannerCheck

  #
  # implement IBurpExtender
  #

  def registerExtenderCallbacks(callbacks)
    # keep a reference to our callbacks object
    @callbacks = callbacks

    # obtain an extension helpers object
    @helpers = callbacks.getHelpers

    # set our extension name
    callbacks.setExtensionName 'WordPress PHP Object Injection Check'

    # register ourselves as a custom scanner check
    callbacks.registerScannerCheck self
  end

  # helper method to search a response for occurrences of a literal match string
  # and return a list of start/end offsets

  def _get_matches(response, match)
    matches = ArrayList.new
    start = 0
    while start < response.length
      start = @helpers.indexOf(response, match, true, start, response.length)
      break if start == -1
      matches.add [start, start + match.length].to_java :int
      start += match.length
    end

    return matches
  end

  #
  # implement IScannerCheck
  #

  def doPassiveScan(baseRequestResponse)
    # look for matches of our passive check grep string
    matches = self._get_matches(baseRequestResponse.getResponse, GREP_STRING_BYTES)
    return nil if matches.length == 0

    # report the issue
    issues = ArrayList.new
    issues.add CustomScanIssue.new(
      baseRequestResponse.getHttpService,
      @helpers.analyzeRequest(baseRequestResponse).getUrl,
      [@callbacks.applyMarkers(baseRequestResponse, nil, matches)],
      'WordPress PHP Object Injection',
      'Submitting the serialized string O:20:"PHP_Object_Injection":0:{} returned: ' + GREP_STRING,
      'High').to_java IScanIssue

    return issues
  end

  def doActiveScan(baseRequestResponse, insertionPoint)
    # make a request containing our injection test in the insertion point
    checkRequest = insertionPoint.buildRequest INJ_TEST
    checkRequestResponse = @callbacks.makeHttpRequest(
        baseRequestResponse.getHttpService, checkRequest)

    # look for matches of our active check grep string
    matches = self._get_matches(checkRequestResponse.getResponse, INJ_ERROR_BYTES)
    return nil if matches.length == 0

    # get the offsets of the payload within the request, for in-UI highlighting
    requestHighlights = [insertionPoint.getPayloadOffsets(INJ_TEST)]

    # report the issue
    issues = ArrayList.new
    issues.add CustomScanIssue.new(
      baseRequestResponse.getHttpService,
      @helpers.analyzeRequest(baseRequestResponse).getUrl,
      [@callbacks.applyMarkers(checkRequestResponse, requestHighlights, matches)],
      'WordPress PHP Object Injection',
      'Submitting the serialized string O:20:"PHP_Object_Injection":0:{} returned: ' + INJ_ERROR,
      'High').to_java IScanIssue

    return issues
  end

  def consolidateDuplicateIssues(existingIssue, newIssue)
    # This method is called when multiple issues are reported for the same URL
    # path by the same extension-provided check. The value we return from this
    # method determines how/whether Burp consolidates the multiple issues
    # to prevent duplication
    #
    # Since the issue name is sufficient to identify our issues as different,
    # if both issues have the same name, only report the existing issue
    # otherwise report both issues
    if existingIssue.getIssueName == newIssue.getIssueName
      return -1
    else
      return 0
    end
  end
end

#
# class implementing IScanIssue to hold our custom scan issue details
#
class CustomScanIssue
  include IScanIssue

  def initialize(httpService, url, httpMessages, name, detail, severity)
    @httpService = httpService
    @url = url
    @httpMessages = httpMessages
    @name = name
    @detail = detail
    @severity = severity
  end

  def getUrl()
    @url
  end

  def getIssueName()
    @name
  end

  def getIssueType()
    0
  end

  def getSeverity()
    @severity
  end

  def getConfidence()
    'Certain'
  end

  def getIssueBackground()
    nil
  end

  def getRemediationBackground()
    nil
  end

  def getIssueDetail()
    @detail
  end

  def getRemediationDetail()
    nil
  end

  def getHttpMessages()
    @httpMessages
  end

  def getHttpService()
    @httpService
  end
end
