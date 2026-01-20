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
                    powershell '''
                    $json = $env:FIREBASE_CREDENTIALS
                    $filePath = "$env:TEMP\\firebase-credentials.json"
                    
                    # Write the JSON to file
                    Set-Content -Path $filePath -Value $json -Encoding UTF8 -NoNewline
                    
                    # Verify file was created
                    if (Test-Path $filePath) {
                        Write-Host "Credentials file created successfully at: $filePath"
                    } else {
                        throw "Failed to create credentials file"
                    }
                    
                    # Set the environment variable and distribute in the same command
                    $env:GOOGLE_APPLICATION_CREDENTIALS = $filePath
                    
                    Write-Host "Using credentials from: $env:GOOGLE_APPLICATION_CREDENTIALS"
                    
                    # Distribute to Firebase
                    firebase appdistribution:distribute build\\app\\outputs\\flutter-apk\\app-release.apk `
                        --app $env:FIREBASE_APP_ID `
                        --release-notes "New APK build from Jenkins!" `
                        --groups $env:FIREBASE_TESTER_GROUP
                    
                    if ($LASTEXITCODE -ne 0) {
                        throw "Firebase distribution failed with exit code $LASTEXITCODE"
                    }
                    
                    Write-Host "APK distributed successfully!"
                    
                    # Clean up
                    Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
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
                    powershell '''
                    $json = $env:FIREBASE_CREDENTIALS
                    $filePath = "$env:TEMP\\firebase-credentials.json"
                    
                    # Write the JSON to file
                    Set-Content -Path $filePath -Value $json -Encoding UTF8 -NoNewline
                    
                    # Verify file was created
                    if (Test-Path $filePath) {
                        Write-Host "Credentials file created successfully at: $filePath"
                    } else {
                        throw "Failed to create credentials file"
                    }
                    
                    # Set the environment variable and distribute in the same command
                    $env:GOOGLE_APPLICATION_CREDENTIALS = $filePath
                    
                    Write-Host "Using credentials from: $env:GOOGLE_APPLICATION_CREDENTIALS"
                    
                    # Distribute to Firebase
                    firebase appdistribution:distribute build\\app\\outputs\\bundle\\release\\app-release.aab `
                        --app $env:FIREBASE_APP_ID `
                        --release-notes "New AAB build from Jenkins!" `
                        --groups $env:FIREBASE_TESTER_GROUP
                    
                    if ($LASTEXITCODE -ne 0) {
                        throw "Firebase distribution failed with exit code $LASTEXITCODE"
                    }
                    
                    Write-Host "AAB distributed successfully!"
                    
                    # Clean up
                    Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
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
