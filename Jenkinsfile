pipeline {
    agent any

    environment {
        FIREBASE_APP_ID = '1:999961822980:android:1d03ab3c4629ddc31f3251'
        FIREBASE_TESTER_GROUP = 'qa-team'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/tzrfabian/wp-fcm-test.git'
            }
        }

        stage('Setup Flutter' ) {
            steps {
                bat 'flutter clean'
                bat 'flutter pub get'
            }
        }

        stage('Build APK') {
            steps {
                bat 'flutter build apk --release'
            }
        }

        stage('Distribute APK to Firebase') {
            steps {
                withCredentials([string(credentialsId: 'firebase-service-account-json', variable: 'FIREBASE_CREDENTIALS')]) {
                    bat '''
                    REM Create the credentials file
                    echo %FIREBASE_CREDENTIALS% > %TEMP%\\firebase-credentials.json
                    
                    REM Debug: Check if file was created
                    if exist %TEMP%\\firebase-credentials.json (
                        echo File created successfully
                        type %TEMP%\\firebase-credentials.json
                    ) else (
                        echo ERROR: File was not created!
                    )
                    
                    REM Set the environment variable
                    set GOOGLE_APPLICATION_CREDENTIALS=%TEMP%\\firebase-credentials.json
                    
                    REM Try to distribute
                    firebase appdistribution:distribute build\\app\\outputs\\flutter-apk\\app-release.apk ^
                        --app %FIREBASE_APP_ID% ^
                        --release-notes "New APK build from Jenkins!" ^
                        --groups "%FIREBASE_TESTER_GROUP%"
                    
                    REM Clean up
                    del %TEMP%\\firebase-credentials.json
                    '''
                }
            }
        }


        stage('Build AAB') {
            steps {
                bat 'flutter build appbundle --release'
            }
        }

        stage('Distribute AAB to Firebase') {
            steps {
                withCredentials([string(credentialsId: 'firebase-service-account-json', variable: 'FIREBASE_CREDENTIALS')]) {
                    bat '''
                    echo %FIREBASE_CREDENTIALS% > %TEMP%\\firebase-credentials.json
                    set GOOGLE_APPLICATION_CREDENTIALS=%TEMP%\\firebase-credentials.json
                    
                    firebase appdistribution:distribute build\\app\\outputs\\bundle\\release\\app-release.aab ^
                        --app %FIREBASE_APP_ID% ^
                        --release-notes "New AAB build from Jenkins!" ^
                        --groups "%FIREBASE_TESTER_GROUP%"
                    
                    del %TEMP%\\firebase-credentials.json
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                if (!isUnix()) {
                    echo "Skipping workspace cleanup on Windows to avoid file locking issues"
                } else {
                    cleanWs()
                }
            }
        }
    }
}
