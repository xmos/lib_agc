@Library('xmos_jenkins_shared_library@develop') _

getApproval()

pipeline {
  agent {
    label 'x86_64 && brew && macOS'
  }
  environment {
    REPO = 'lib_agc'
    VIEW = "${env.JOB_NAME.contains('PR-') ? REPO+'_'+env.CHANGE_TARGET : REPO+'_'+env.BRANCH_NAME}"
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
              runWaf('.')
              viewEnv() {
                runPytest()
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
            runWaf('.')
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
