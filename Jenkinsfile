@Library('xmos_jenkins_shared_library@v0.32.0') _

getApproval()

pipeline {
  agent none

  //Tools for AI verif stage. Tools for standard stage in view file
  environment {
      REPO = 'lib_agc'
      VIEW = getViewName(REPO)
  }
  stages {
    stage('Standard build and XS2 tests') {
      agent {
        label 'x86_64 && linux'
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
        stage('Build docs') {
          steps {
            runXdoc("${REPO}/${REPO}/doc")
            // Archive all the generated .pdf docs
            archiveArtifacts artifacts: "${REPO}/**/pdf/*.pdf", fingerprint: true, allowEmptyArchive: true
          }
        }
      }
      post {
        cleanup {
          xcoreCleanSandbox()
        }
      }
    }
    stage('xcore.ai Verification'){
      agent {
        label 'xcore.ai'
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
        stage('xs3 agc_unit_tests')
        {
          steps {
            dir("${REPO}") {
              dir('tests') {
                dir('agc_unit_tests') {
                  withVenv {
                    unstash 'agc_unit_tests'
                    viewEnv() {
                      runPython("TARGET=XCOREAI pytest -s")
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
        label 'x86_64 && linux'
      }
      when {
        expression { return currentBuild.currentResult == "SUCCESS" }
      }
      steps {
        updateViewfiles()
      }
    }
  }
}
