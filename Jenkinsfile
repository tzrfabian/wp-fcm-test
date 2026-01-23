pipeline {
    agent any

    environment {
        FIREBASE_APP_ID = '1:999961822980:android:1d03ab3c4629ddc31f3251'
        FIREBASE_TESTER_GROUP = 'qa-test'
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
                withCredentials([file(credentialsId: 'firebase-service-account-json', variable: 'FIREBASE_CREDENTIALS_FILE')]) {
                    powershell '''
                    # Use the credentials file path provided by Jenkins
                    $credentialsPath = $env:FIREBASE_CREDENTIALS_FILE
                    
                    Write-Host "Using credentials file at: $credentialsPath"
                    
                    # Verify file exists
                    if (Test-Path $credentialsPath) {
                        Write-Host "Credentials file found successfully"
                        
                        # Read and validate JSON structure (without exposing sensitive data)
                        try {
                            $jsonContent = Get-Content $credentialsPath -Raw | ConvertFrom-Json
                            Write-Host "Service account email: $($jsonContent.client_email)"
                            Write-Host "Project ID: $($jsonContent.project_id)"
                            
                            if ($jsonContent.project_id -ne "wp-fcm-test") {
                                Write-Warning "Project ID mismatch! Expected 'wp-fcm-test', got '$($jsonContent.project_id)'"
                            }
                        } catch {
                            Write-Error "Failed to parse credentials JSON: $_"
                            throw
                        }
                    } else {
                        throw "Credentials file not found at: $credentialsPath"
                    }
                    
                    # Set the environment variable
                    $env:GOOGLE_APPLICATION_CREDENTIALS = $credentialsPath
                    
                    Write-Host "GOOGLE_APPLICATION_CREDENTIALS set to: $env:GOOGLE_APPLICATION_CREDENTIALS"
                    Write-Host "Firebase App ID: $env:FIREBASE_APP_ID"
                    Write-Host "Tester Group: $env:FIREBASE_TESTER_GROUP"
                    
                    # Distribute to Firebase with service account
                    Write-Host "Starting Firebase distribution..."
                    firebase appdistribution:distribute build\\app\\outputs\\flutter-apk\\app-release.apk `
                        --app $env:FIREBASE_APP_ID `
                        --release-notes "New APK build from Jenkins!" `
                        --groups $env:FIREBASE_TESTER_GROUP
                    
                    if ($LASTEXITCODE -ne 0) {
                        throw "Firebase distribution failed with exit code $LASTEXITCODE"
                    }
                    
                    Write-Host "APK distributed successfully!"
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
                withCredentials([file(credentialsId: 'firebase-service-account-json', variable: 'FIREBASE_CREDENTIALS_FILE')]) {
                    powershell '''
                    # Use the credentials file path provided by Jenkins
                    $credentialsPath = $env:FIREBASE_CREDENTIALS_FILE
                    
                    Write-Host "Using credentials file at: $credentialsPath"
                    
                    # Verify file exists
                    if (Test-Path $credentialsPath) {
                        Write-Host "Credentials file found successfully"
                    } else {
                        throw "Credentials file not found at: $credentialsPath"
                    }
                    
                    # Set the environment variable
                    $env:GOOGLE_APPLICATION_CREDENTIALS = $credentialsPath
                    
                    # Distribute to Firebase with service account
                    firebase appdistribution:distribute build\\app\\outputs\\bundle\\release\\app-release.aab `
                        --app $env:FIREBASE_APP_ID `
                        --release-notes "New AAB build from Jenkins!" `
                        --groups $env:FIREBASE_TESTER_GROUP
                    
                    if ($LASTEXITCODE -ne 0) {
                        throw "Firebase distribution failed with exit code $LASTEXITCODE"
                    }
                    
                    Write-Host "AAB distributed successfully!"
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
