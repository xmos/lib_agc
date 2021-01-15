@Library('xmos_jenkins_shared_library@v0.15.1') _

getApproval()

pipeline {
  agent none

  //Tools for AI verif stage. Tools for standard stage in view file
  parameters {
     string(
       name: 'TOOLS_VERSION',
       defaultValue: '15.0.2',
       description: 'The tools version to build with (check /projects/tools/ReleasesTools/)'
     )
   }
  stages {
    stage('Standard build and XS2 tests') {      
    agent {
      label 'x86_64 && brew && macOS'
    }
    environment {
        REPO = 'lib_agc'
        //VIEW = getViewName(REPO)
        VIEW = "lib_agc_develop_tools15"
    }
    options {
        skipDefaultCheckout()
    }
    stages {
    stage('Get View') {
      steps {
        xcorePrepareSandbox("${VIEW}", "${REPO}")
      }
    }
    stage('Library Checks') {
      steps {
        xcoreLibraryChecks("${REPO}")
      }
    }
    stage('Unit Tests') {
      steps {
        dir("${REPO}") {
          dir('tests') {
            dir('agc_unit_tests') {
              withVenv {
              runWaf('.', "configure clean build --target=xcore200")
              runWaf('.', "configure clean build --target=xcoreai")
              stash name: 'agc_unit_tests', includes: 'bin/*xcoreai.xe, '              
              viewEnv() {
                runPython("TARGET=XCORE200 pytest -n 1")
              }
              }
            }
          }
        }
      }
    }
    stage('Build test_wav_agc') {
      steps {
        dir("${REPO}") {
          dir('tests/test_wav_agc') {
            withVenv {
            runWaf('.', "configure clean build --target=xcore200")
            runWaf('.', "configure clean build --target=xcoreai")
           }
          }
        }
      }
    }
    stage('Build') {
      steps {
        dir("${REPO}") {
          // xcoreAllAppsBuild('examples')
          dir("${REPO}") {
            runXdoc('doc')
          }
        }
      }
    }
  }
  
  post {
    success {
      updateViewfiles()
    }
    cleanup {
      xcoreCleanSandbox()
    }
  }
  }
    stage('xcore.ai Verification'){
      agent {
        label 'xcore.ai-explorer'
      }      
      environment {
        // '/XMOS/tools' from get_tools.py and rest from tools installers
        TOOLS_PATH = "/XMOS/tools/${params.TOOLS_VERSION}/XMOS/xTIMEcomposer/${params.TOOLS_VERSION}"
        REPO = 'lib_agc'
        //VIEW = getViewName(REPO)
        VIEW = "lib_agc_develop_tools15"
      }
      options {
        skipDefaultCheckout()
      }

      stages{

        stage('Get View') {
            steps {
                xcorePrepareSandbox("${VIEW}", "${REPO}")
            }
        }
        stage('Install Dependencies') {
          steps {
            sh '/XMOS/get_tools.py ' + params.TOOLS_VERSION
            installDependencies()
          }
        }          
        stage('xs3 agc_unit_tests')
        {
          steps {
            dir("${REPO}") {
            dir('tests') {
            dir('agc_unit_tests') {
              withVenv {
                unstash 'agc_unit_tests'
                viewEnv() {
                runPython("TARGET=XCOREAI pytest -n 1")
              }
            }
            }
            }
           }
          }
        }
      } //stages
      post {
        cleanup {
          cleanWs()
        }
      }
  }//xcore.ai
  stage('Update view files') {
    agent {
      label 'x86_64&&brew'
    }
    when {
      expression { return currentBuild.result == "SUCCESS" }
    }
    steps {
      updateViewfiles()
    }
  }
  }
}
