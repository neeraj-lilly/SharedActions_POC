import groovy.json.JsonSlurper
import groovy.json.JsonOutput;

// TODO: should take build dir as arg1, e.g. $0 lint|test ./VirtualClaudia/build
if (args[0] == "lint") {
    List json = new JsonSlurper().parse(new File("./build/swiftlint.result.json").newReader()) 
    def output = "Done Linting. Found ${json.size()} violation(s).\n\n"
    // print output
} else if (args[0] == "test") {
    def xml = new XmlParser().parse("./build/report.junit")
    def output = "${xml.attributes()['tests'].toInteger()} test(s) total, ${xml.attributes()['failures'].toInteger()} failed.\n\n"
    print output
} else {
    print "WARNING unknown argument, should be 'lint' or 'test'"
}
