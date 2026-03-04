buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val rootProjectBuildDir = project.rootProject.layout.buildDirectory.dir("../../build")

subprojects {
    project.layout.buildDirectory.set(rootProjectBuildDir.map { it.dir(project.name) })
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
