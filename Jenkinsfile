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
  }
  post {
    cleanup {
      cleanWs()
    }
  }
}
