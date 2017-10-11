import xmostest

def runtest():
    resources = xmostest.request_resource("xsim")
     
    tester = xmostest.ComparisonTester(open('app_agc_test.expect'),
                                       'lib_agc', 'simple_tests',
                                       'app_agc_test', {})
     
    xmostest.run_on_simulator(resources['xsim'],
                              '../examples/app_agc_test/bin/app_agc_test.xe',
                              tester=tester, timeout=1200)
