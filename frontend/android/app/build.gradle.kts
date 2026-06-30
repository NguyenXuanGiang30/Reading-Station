import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("keystore.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

fun isReleaseTaskRequested(): Boolean =
    gradle.startParameter.taskNames.any { taskName ->
        taskName.contains("release", ignoreCase = true)
    }

fun resolveConfig(vararg keys: String, defaultValue: String = ""): String {
    for (key in keys) {
        val gradleValue = providers.gradleProperty(key).orNull
        if (!gradleValue.isNullOrBlank()) {
            return gradleValue
        }

        val envValue = System.getenv(key)
        if (!envValue.isNullOrBlank()) {
            return envValue
        }

        val propertyValue = keystoreProperties.getProperty(key)
        if (!propertyValue.isNullOrBlank()) {
            return propertyValue
        }
    }

    return defaultValue
}

val placeholderAppId = "com.example.frontend"
val configuredAppId = resolveConfig("APP_ID", defaultValue = placeholderAppId)
val configuredAppName = resolveConfig("APP_NAME", defaultValue = "Tram Doc")
val facebookAppId = resolveConfig("FACEBOOK_APP_ID")
val facebookClientToken = resolveConfig("FACEBOOK_CLIENT_TOKEN")

val releaseStoreFilePath = resolveConfig("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseStorePassword = resolveConfig("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias = resolveConfig("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = resolveConfig("keyPassword", "ANDROID_KEY_PASSWORD")
val hasReleaseSigning = listOf(
    releaseStoreFilePath,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { it.isNotBlank() }
val allowDebugSigningForRelease = resolveConfig(
    "ALLOW_DEBUG_SIGNING_FOR_RELEASE",
    defaultValue = "true",
).toBoolean()
val googleServicesFile = project.file("google-services.json")
val isReleaseTask = isReleaseTaskRequested()

if (isReleaseTask && hasReleaseSigning) {
    if (configuredAppId == placeholderAppId) {
        throw GradleException(
            "Release signing is configured but APP_ID is still the placeholder " +
                "\"$placeholderAppId\". Provide the real production APP_ID before publishing.",
        )
    }

    if (!googleServicesFile.exists()) {
        throw GradleException(
            "Release signing is configured but android/app/google-services.json is missing. " +
                "Add the production Firebase config that matches APP_ID=$configuredAppId.",
        )
    }

    val googleServicesContents = googleServicesFile.readText()
    if (!googleServicesContents.contains("\"package_name\": \"$configuredAppId\"")) {
        throw GradleException(
            "android/app/google-services.json does not match APP_ID=$configuredAppId. " +
                "Download the Firebase config for the production application id before publishing.",
        )
    }
}

android {
    namespace = configuredAppId
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = configuredAppId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["usesCleartextTraffic"] = "true"
        resValue("string", "app_name", configuredAppName)
        resValue("string", "facebook_app_id", facebookAppId)
        resValue("string", "facebook_client_token", facebookClientToken)
        resValue(
            "string",
            "fb_login_protocol_scheme",
            if (facebookAppId.isNotBlank()) "fb$facebookAppId" else "",
        )
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFilePath)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["usesCleartextTraffic"] = "true"
        }
        release {
            manifestPlaceholders["usesCleartextTraffic"] = "true"
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else if (allowDebugSigningForRelease) {
                signingConfig = signingConfigs.getByName("debug")
            } else {
                throw GradleException(
                    "Release signing is not configured. Provide android/keystore.properties " +
                        "or environment variables. For local verification only, pass " +
                        "-PALLOW_DEBUG_SIGNING_FOR_RELEASE=true.",
                )
            }
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
