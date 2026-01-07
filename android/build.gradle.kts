allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Fix for legacy Flutter plugins missing namespace (required for AGP 8.0+)
// and JVM target compatibility issues
subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.getByName("android") as com.android.build.gradle.LibraryExtension
        
        // Fix namespace for legacy plugins
        if (android.namespace == null) {
            val nameMap = mapOf(
                "flutter_usb_printer" to "app.mylekha.client.flutter_usb_printer",
                "flutter_pos_printer_platform" to "com.flutter.pos.printer",
                "network_info_plus" to "com.network.info.plus",
                "imin_printer" to "com.imin.printer"
            )
            val ns = nameMap[project.name]
            if (ns != null) {
                android.namespace = ns
                println("✅ Injected namespace for ${project.name}: $ns")
            } else {
                // Fallback: try to read from AndroidManifest.xml
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifest = groovy.xml.XmlSlurper().parse(manifestFile)
                    val packageName = manifest.getProperty("@package").toString()
                    if (packageName.isNotEmpty()) {
                        android.namespace = packageName
                        println("✅ Injected namespace from manifest for ${project.name}: $packageName")
                    }
                }
            }
        }
        
        // Fix Java compatibility
        android.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_11
            targetCompatibility = JavaVersion.VERSION_11
        }
    }
    
    // Fix Kotlin JVM target to match Java
    plugins.withId("org.jetbrains.kotlin.android") {
        extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}