allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val javaTaskName = name.replace("Kotlin", "JavaWithJavac")
        val javaTask = project.tasks.findByName(javaTaskName) as? JavaCompile
        val target = javaTask?.targetCompatibility ?: project.tasks.withType<JavaCompile>().firstOrNull()?.targetCompatibility ?: "17"
        val jvmTargetValue = if (target == "1.8" || target == "8") {
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
        } else if (target == "11") {
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
        } else {
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
        compilerOptions {
            jvmTarget.set(jvmTargetValue)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
