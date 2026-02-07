import org.gradle.api.JavaVersion
import org.gradle.api.tasks.Delete
import org.gradle.api.tasks.compile.JavaCompile

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory = file("../build")

subprojects {
    layout.buildDirectory = rootProject.layout.buildDirectory.dir(project.name).get()
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_11.toString()
        targetCompatibility = JavaVersion.VERSION_11.toString()
  }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
