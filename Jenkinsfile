pipeline {
  agent {
    label 'x86&&macOS&&Apps'
  }
  environment {
    VIEW = 'agc'
    REPO = 'lib_agc'
  }
  options {
    skipDefaultCheckout()
  }
  stages {
    stage('Get View') {
      steps {
        prepareAppsSandbox("${VIEW}", "${REPO}")
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
              runXwaf('.')
              viewEnv() {
                runPytest()
              }
            }
          }
        }
      }
    }
  }
  post {
    success {
      updateViewfiles()
    }
    failure {
      dir("${REPO}") {
        dir('tests') {
          dir('agc_unit_tests') {
            junit 'pytest_result.xml'
          }
        }
      }
    }
    cleanup {
      cleanWs()
    }
  }
}
