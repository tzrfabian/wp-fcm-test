// Jenkinsfile for Windows - Flutter App Building and Firebase Distribution
// Use this version if you're running Jenkins on Windows

pipeline {
    agent any

    environment {
        // Get these from your Firebase project settings
        FIREBASE_APP_ID = 'wp-fcm-test'
        // The name of the tester group you created in Firebase
        FIREBASE_TESTER_GROUP = 'qa-team'
    }

    stages {
        stage('Checkout') {
            steps {
                // Clone the repository
                git branch: 'main', url: 'https://github.com/tzrfabian/wp-fcm-test.git'
            }
        }

        stage('Setup Flutter') {
            steps {
                // Use 'bat' instead of 'sh' for Windows
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
                    REM Create a temporary file with the Firebase credentials
                    echo %FIREBASE_CREDENTIALS% > %TEMP%\\firebase-credentials.json
                    
                    REM Set the environment variable for Firebase CLI
                    set GOOGLE_APPLICATION_CREDENTIALS=%TEMP%\\firebase-credentials.json
                    
                    REM Distribute the APK
                    firebase appdistribution:distribute build\\app\\outputs\\flutter-apk\\app-release.apk ^
                        --app %FIREBASE_APP_ID% ^
                        --release-notes "New APK build from Jenkins!" ^
                        --groups "%FIREBASE_TESTER_GROUP%"
                    
                    REM Clean up the temporary file
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
                    REM Create a temporary file with the Firebase credentials
                    echo %FIREBASE_CREDENTIALS% > %TEMP%\\firebase-credentials.json
                    
                    REM Set the environment variable for Firebase CLI
                    set GOOGLE_APPLICATION_CREDENTIALS=%TEMP%\\firebase-credentials.json
                    
                    REM Distribute the AAB
                    firebase appdistribution:distribute build\\app\\outputs\\bundle\\release\\app-release.aab ^
                        --app %FIREBASE_APP_ID% ^
                        --release-notes "New AAB build from Jenkins!" ^
                        --groups "%FIREBASE_TESTER_GROUP%"
                    
                    REM Clean up the temporary file
                    del %TEMP%\\firebase-credentials.json
                    '''
                }
            }
        }
    }

    post {
        always {
            // Clean up the workspace after the pipeline runs
            cleanWs()
        }
    }
}
