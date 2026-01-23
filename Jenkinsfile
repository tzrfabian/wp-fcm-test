pipeline {
    agent any

    parameters {
        string(
            name: 'BRANCH',
            defaultValue: 'main',
            description: 'Enter the branch name to build (e.g., main, develop, feature/xyz)'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['development', 'staging', 'production'],
            description: 'Select the environment/mode for this build'
        )
        string(
            name: 'VERSION',
            defaultValue: '1.0.0',
            description: 'Enter the version number (e.g., 1.0.0)'
        )
        text(
            name: 'RELEASE_NOTES',
            defaultValue: 'New APK build from Jenkins',
            description: 'Enter release notes for this build'
        )
    }

    environment {
        FIREBASE_APP_ID = '1:999961822980:android:1d03ab3c4629ddc31f3251'
        FIREBASE_TESTER_GROUP = 'qa-test'
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Checking out branch: ${BRANCH}"
                    echo "Environment: ${ENVIRONMENT}"
                }
                git branch: '${BRANCH}', url: 'https://github.com/tzrfabian/wp-fcm-test.git'
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
                script {
                    echo "Building APK for ${ENVIRONMENT} environment"
                }
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
                    
                    # Logout any existing Firebase CLI user sessions
                    Write-Host "Logging out any existing Firebase CLI sessions..."
                    firebase logout --force 2>&1 | Out-Null
                    
                    # Set the environment variable
                    $env:GOOGLE_APPLICATION_CREDENTIALS = $credentialsPath
                    
                    Write-Host "========================================="
                    Write-Host "Build Information:"
                    Write-Host "========================================="
                    Write-Host "Branch: $env:BRANCH"
                    Write-Host "Environment: $env:ENVIRONMENT"
                    Write-Host "Version: $env:VERSION"
                    Write-Host "Firebase App ID: $env:FIREBASE_APP_ID"
                    Write-Host "Tester Group: $env:FIREBASE_TESTER_GROUP"
                    Write-Host "========================================="
                    
                    # Verify APK exists
                    $apkPath = "build\\app\\outputs\\flutter-apk\\app-release.apk"
                    if (Test-Path $apkPath) {
                        $apkSize = (Get-Item $apkPath).Length / 1MB
                        Write-Host "APK found: $apkPath (Size: $([math]::Round($apkSize, 2)) MB)"
                    } else {
                        throw "APK not found at: $apkPath"
                    }
                    
                    # Distribute to Firebase with service account
                    Write-Host "Starting Firebase distribution..."
                    Write-Host "Using service account authentication via GOOGLE_APPLICATION_CREDENTIALS"
                    Write-Host "Release Notes: $env:RELEASE_NOTES"
                    firebase appdistribution:distribute $apkPath `
                        --app $env:FIREBASE_APP_ID `
                        --release-notes $env:RELEASE_NOTES `
                        --groups $env:FIREBASE_TESTER_GROUP `
                        --debug
                    
                    if ($LASTEXITCODE -ne 0) {
                        throw "Firebase distribution failed with exit code $LASTEXITCODE"
                    }
                    
                    Write-Host "APK distributed successfully!"
                    '''
                }
            }
        }


        stage('Build AAB') {
            when {
                expression { return false } // Disabled: AAB distribution requires Google Play Console integration
            }
            steps {
                bat 'flutter build appbundle --release'
            }
        }

        stage('Distribute AAB to Firebase') {
            when {
                expression { return false } // Disabled: AAB distribution requires Google Play Console integration
            }
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
                    
                    # Logout any existing Firebase CLI user sessions
                    Write-Host "Logging out any existing Firebase CLI sessions..."
                    firebase logout --force 2>&1 | Out-Null
                    
                    # Set the environment variable
                    $env:GOOGLE_APPLICATION_CREDENTIALS = $credentialsPath
                    
                    # Distribute to Firebase with service account
                    firebase appdistribution:distribute build\\app\\outputs\\bundle\\release\\app-release.aab `
                        --app $env:FIREBASE_APP_ID `
                        --release-notes $env:RELEASE_NOTES `
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
                    echo "========================================="
                    echo "Build Summary:"
                    echo "========================================="
                    echo "Branch: ${BRANCH}"
                    echo "Environment: ${ENVIRONMENT}"
                    echo "Version: ${VERSION}"
                    echo "========================================="
                } else {
                    cleanWs()
                }
            }
        }
    }
}
