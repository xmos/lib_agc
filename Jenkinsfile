@Library('xmos_jenkins_shared_library@develop') _
pipeline {
  agent {
    // Don't run on an old agent, brew install fftw fails!
    label 'x86 && macOS && !macOS_10_11 && brew'
        
  }
  environment {
    VIEW = 'lib_agc_develop'
    REPO = 'lib_agc'
  }
  options {
    skipDefaultCheckout()
  }
  triggers {
    /* Trigger this Pipeline on changes to the repos dependencies
     *
     * If this Pipeline is running in a pull request, the triggers are set
     * on the base branch the PR is set to merge in to.
     *
     * Otherwise the triggers are set on the branch of a matching name to the
     * one this Pipeline is on.
     */
    upstream(
      upstreamProjects:
        (env.JOB_NAME.contains('PR-') ?
          "../audio_test_tools/${env.CHANGE_TARGET}," +
          "../lib_dsp/${env.CHANGE_TARGET}," +
          "../lib_vad/${env.CHANGE_TARGET}," +
          "../lib_voice_toolbox/${env.CHANGE_TARGET}"
        :
          "../audio_test_tools/${env.BRANCH_NAME}," +
          "../lib_dsp/${env.BRANCH_NAME}," +
          "../lib_vad/${env.BRANCH_NAME}," +
          "../lib_voice_toolbox/${env.BRANCH_NAME}"),
      threshold: hudson.model.Result.SUCCESS
    )
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
              runXwaf('.')
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
            runXwaf('.')
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
