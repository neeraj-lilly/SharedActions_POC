import groovy.json.JsonSlurper
import groovy.json.JsonOutput;

// TODO: should take build dir as arg1, e.g. $0 lint|test ./VirtualClaudia/build
if (args[0] == "lint"){
    List json = new JsonSlurper().parse(new File("./build/swiftlint.result.json").newReader()) 
    // remove attributes 
    json.each {
        it.remove('character')
        it.remove('rule_id')
        it.remove('type')
    }

    def result  = json.groupBy({it.file},{it.reason}).collect{[unique: it.value]}
    def output = []
    output << "Done Linting. Found ${json.size()} violations.\n\n"

    // result.each {
    //     def lineno = []
    //     it['unique']["${it['unique'].keySet()[0]}"].eachWithIndex { name,index ->   
    //         if ((it['unique']["${it['unique'].keySet()[0]}"].size() - 1) == index) {
    //             lineno << name['line']
    //         } else {
    //             lineno << name['line']
    //         }

    //         if ((it['unique']["${it['unique'].keySet()[0]}"].size() - 1) == index) {
    //             lineno << name['line']
    //         } else {
    //             lineno << name['line']
    //         }

    //         if ((it['unique']["${it['unique'].keySet()[0]}"].size() - 1) == index) {
    //             output << "FileName: ${name['file']}\nViolation: ${name['reason']}\nLine No.: ${lineno.unique().join(', ')}\n\n"
    //         }
    //     }
    // }
    print output.join('')
} else if (args[0] == "test") {
    def xml = new XmlParser().parse("./build/report.junit")
    xml['testsuite'].findAll { testsuite ->
        testsuite.attributes()['failures'].toInteger() == 0
    }.each { testsuite ->
        testsuite.parent().remove(testsuite)
    }

    def failure_test_cases = []

    xml['testsuite']['testcase'].findAll { testcase ->
        !testcase.attributes()['time']
    }.each { testcase ->
        failure_test_cases << "${testcase.attributes()['classname']}.${testcase.attributes()['name']}\n${testcase['failure'][0].attributes()['message']}\n\n"
    }

    def output = "${xml.attributes()['tests'].toInteger()} test(s) total, ${xml.attributes()['failures'].toInteger()} failed\n\n"

    // if (!stage_result) {
    output += failure_test_cases.join("\n\n")
    // }

    print output
} else {
    print "WARNING unknown argument, should be 'lint' or 'test'"
}
