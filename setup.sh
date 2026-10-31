#!/usr/bin/env bash
set -e

echo "[1/8] Criando estrutura de pastas..."
mkdir -p gradle/wrapper
mkdir -p app/src/main/java/com/freedomlock/data
mkdir -p app/src/main/java/com/freedomlock/service
mkdir -p app/src/main/java/com/freedomlock/ui
mkdir -p app/src/main/java/com/freedomlock/vpn
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/xml

echo "[2/8] Gerando Gradle Wrapper auto-instalável..."

cat << 'EOF' > gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.10.2-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

cat << 'EOF' > gradlew
#!/usr/bin/env sh
PRG="$0"
while [ -h "$PRG" ]; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done
APP_HOME=`dirname "$PRG"`

if [ -n "$JAVA_HOME" ] ; then
    JAVACMD="$JAVA_HOME/bin/java"
else
    JAVACMD="java"
fi

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

if [ ! -f "$CLASSPATH" ]; then
    echo "gradle-wrapper.jar nao encontrado. Baixando..."
    curl -sLo "$CLASSPATH" "https://raw.githubusercontent.com/gradle/gradle/v8.10.2/gradle/wrapper/gradle-wrapper.jar" || \
    wget -qO "$CLASSPATH" "https://raw.githubusercontent.com/gradle/gradle/v8.10.2/gradle/wrapper/gradle-wrapper.jar" || {
        echo "Erro: Nao foi possivel baixar o gradle-wrapper.jar. Verifique sua conexao."
        exit 1
    }
fi

exec "$JAVACMD" "-Dorg.gradle.appname=gradlew" -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
EOF
chmod +x gradlew

cat << 'EOF' > gradlew.bat
@if "%DEBUG%" == "" @echo off
set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_HOME=%DIRNAME%

if defined JAVA_HOME (
    set JAVA_EXE="%JAVA_HOME%/bin/java.exe"
) else (
    set JAVA_EXE=java.exe
)

set WRAPPER_JAR=%APP_HOME%gradle\wrapper\gradle-wrapper.jar
if exist "%WRAPPER_JAR%" goto runWrapper

echo gradle-wrapper.jar nao encontrado. Baixando...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/gradle/gradle/v8.10.2/gradle/wrapper/gradle-wrapper.jar', '%WRAPPER_JAR%') } catch { exit 1 }"
if "%ERRORLEVEL%" == "0" goto runWrapper
exit /b 1

:runWrapper
%JAVA_EXE% "-Dorg.gradle.appname=gradlew" -classpath "%WRAPPER_JAR%" org.gradle.wrapper.GradleWrapperMain %*
EOF

echo "[3/8] Gerando arquivos de build Gradle e Proguard..."

cat << 'EOF' > settings.gradle.kts
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "FreedomLock"
include(":app")
EOF

cat << 'EOF' > build.gradle.kts
plugins {
    id("com.android.application") version "8.7.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
}
EOF

cat << 'EOF' > gradle.properties
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
kotlin.code.style=official
EOF

cat << 'EOF' > app/proguard-rules.pro
-keep class com.freedomlock.FreedomLockApp { *; }
-keep class com.freedomlock.vpn.FreedomVpnService { *; }
-keep class com.freedomlock.service.AppMonitorAccessibilityService { *; }
-keep class com.freedomlock.service.BootReceiver { *; }
-keep class com.freedomlock.data.AppItem { *; }
EOF

cat << 'EOF' > app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.freedomlock"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.freedomlock"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.activity:activity-ktx:1.9.3")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.recyclerview:recyclerview:1.3.2")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
}
EOF

echo "[4/8] Gerando Manifesto e Recursos Visuais..."

cat << 'EOF' > app/src/main/res/drawable/ic_app_logo.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="48dp"
    android:height="48dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#6750A4"
        android:pathData="M18,8h-1V6c0,-2.76 -2.24,-5 -5,-5S7,3.24 7,6v2H6c-1.1,0 -2,0.9 -2,2v10c0,1.1 0.9,2 2,2h12c1.1,0 2,-0.9 2,-2V10c0,-1.1 -0.9,-2 -2,-2zM12,17c-1.1,0 -2,-0.9 -2,-2s0.9,-2 2,-2 2,0.9 2,2 -0.9,2 -2,2zM15.1,8H8.9V6c0,-1.71 1.39,-3.1 3.1,-3.1 1.71,0 3.1,1.39 3.1,3.1v2z"/>
</vector>
EOF

cat << 'EOF' > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions" />
    <uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" tools:ignore="QueryAllPackagesPermission" />

    <application
        android:name=".FreedomLockApp"
        android:allowBackup="false"
        android:icon="@drawable/ic_app_logo"
        android:label="Freedom Lock"
        android:supportsRtl="true"
        android:theme="@style/Theme.FreedomLock">

        <activity
            android:name=".ui.MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/Theme.FreedomLock">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity
            android:name=".ui.BlockScreenActivity"
            android:exported="false"
            android:launchMode="singleTask"
            android:excludeFromRecents="true"
            android:noHistory="true"
            android:theme="@style/Theme.FreedomLock" />

        <service
            android:name=".vpn.FreedomVpnService"
            android:permission="android.permission.BIND_VPN_SERVICE"
            android:foregroundServiceType="specialUse"
            android:exported="false">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="vpn" />
            <intent-filter>
                <action android:name="android.net.VpnService" />
            </intent-filter>
        </service>

        <service
            android:name=".service.AppMonitorAccessibilityService"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
            android:exported="true">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/accessibility_service_config" />
        </service>

        <receiver
            android:name=".service.BootReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
            </intent-filter>
        </receiver>

    </application>
</manifest>
EOF

cat << 'EOF' > app/src/main/res/xml/accessibility_service_config.xml
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagDefault"
    android:canRetrieveWindowContent="false"
    android:description="@string/accessibility_description"
    android:notificationTimeout="100" />
EOF

cat << 'EOF' > app/src/main/res/values/strings.xml
<resources>
    <string name="app_name">Freedom Lock</string>
    <string name="accessibility_description">Monitora aplicativos em primeiro plano para aplicar regras de bloqueio do usuário.</string>
    <string name="vpn_status_active">Filtragem DNS Ativa</string>
    <string name="vpn_status_inactive">Filtragem DNS Desativada</string>
    <string name="accessibility_active">Monitor de Apps Ativo</string>
    <string name="accessibility_inactive">Monitor Desativado (Toque para ativar)</string>
    <string name="tab_apps">Aplicativos</string>
    <string name="tab_domains">Domínios DNS</string>
    <string name="add_domain_hint">Ex: tiktok.com ou doubleclick.net</string>
    <string name="btn_add">Adicionar</string>
</resources>
EOF

cat << 'EOF' > app/src/main/res/values/colors.xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="brand_primary">#6750A4</color>
    <color name="brand_on_primary">#FFFFFF</color>
    <color name="brand_surface">#1C1B1F</color>
    <color name="brand_on_surface">#E6E1E5</color>
    <color name="brand_background">#141218</color>
    <color name="brand_card">#2B2930</color>
    <color name="status_active">#4CAF50</color>
    <color name="status_inactive">#F44336</color>
</resources>
EOF

cat << 'EOF' > app/src/main/res/values/themes.xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.FreedomLock" parent="Theme.Material3.Dark.NoActionBar">
        <item name="colorPrimary">@color/brand_primary</item>
        <item name="colorOnPrimary">@color/brand_on_primary</item>
        <item name="android:colorBackground">@color/brand_background</item>
        <item name="colorSurface">@color/brand_surface</item>
        <item name="colorOnSurface">@color/brand_on_surface</item>
    </style>
</resources>
EOF

echo "[5/8] Gerando Layouts..."

cat << 'EOF' > app/src/main/res/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@color/brand_background"
    android:padding="16dp">

    <com.google.android.material.card.MaterialCardView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        app:cardBackgroundColor="@color/brand_card"
        app:cardCornerRadius="16dp"
        app:strokeWidth="0dp"
        android:layout_marginBottom="12dp">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:gravity="center_vertical"
            android:padding="16dp">

            <LinearLayout
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                android:orientation="vertical">

                <TextView
                    android:id="@+id/tvVpnStatus"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:text="@string/vpn_status_inactive"
                    android:textColor="@color/brand_on_surface"
                    android:textSize="16sp"
                    android:textStyle="bold" />

                <TextView
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:text="Filtragem DNS local (UDP 53)"
                    android:textColor="#A09FA5"
                    android:textSize="12sp" />
            </LinearLayout>

            <com.google.android.material.materialswitch.MaterialSwitch
                android:id="@+id/switchVpn"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content" />
        </LinearLayout>
    </com.google.android.material.card.MaterialCardView>

    <com.google.android.material.card.MaterialCardView
        android:id="@+id/cardAccessibility"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        app:cardBackgroundColor="@color/brand_card"
        app:cardCornerRadius="16dp"
        app:strokeWidth="0dp"
        android:layout_marginBottom="16dp">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            android:padding="16dp">

            <TextView
                android:id="@+id/tvAccessibilityStatus"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="@string/accessibility_inactive"
                android:textColor="@color/status_inactive"
                android:textSize="14sp"
                android:textStyle="bold" />

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Necessário para interceptar aplicativos proibidos."
                android:textColor="#A09FA5"
                android:textSize="12sp"
                android:layout_marginTop="4dp" />
        </LinearLayout>
    </com.google.android.material.card.MaterialCardView>

    <com.google.android.material.tabs.TabLayout
        android:id="@+id/tabLayout"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:background="@color/brand_background"
        app:tabIndicatorColor="@color/brand_primary"
        app:tabSelectedTextColor="@color/brand_on_surface"
        app:tabTextColor="#A09FA5">

        <com.google.android.material.tabs.TabItem
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/tab_apps" />

        <com.google.android.material.tabs.TabItem
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/tab_domains" />
    </com.google.android.material.tabs.TabLayout>

    <FrameLayout
        android:id="@+id/layoutApps"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:layout_marginTop="8dp">

        <ProgressBar
            android:id="@+id/progressApps"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_gravity="center" />

        <androidx.recyclerview.widget.RecyclerView
            android:id="@+id/rvApps"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:visibility="gone" />
    </FrameLayout>

    <LinearLayout
        android:id="@+id/layoutDomains"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:orientation="vertical"
        android:visibility="gone"
        android:layout_marginTop="8dp">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:gravity="center_vertical">

            <com.google.android.material.textfield.TextInputLayout
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                android:hint="@string/add_domain_hint">

                <com.google.android.material.textfield.TextInputEditText
                    android:id="@+id/etDomain"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:inputType="textUri"
                    android:singleLine="true" />
            </com.google.android.material.textfield.TextInputLayout>

            <Button
                android:id="@+id/btnAddDomain"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="@string/btn_add"
                android:layout_marginStart="8dp" />
        </LinearLayout>

        <androidx.recyclerview.widget.RecyclerView
            android:id="@+id/rvDomains"
            android:layout_width="match_parent"
            android:layout_height="0dp"
            android:layout_weight="1"
            android:layout_marginTop="8dp" />
    </LinearLayout>

</LinearLayout>
EOF

cat << 'EOF' > app/src/main/res/layout/item_app_lock.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:gravity="center_vertical"
    android:padding="12dp">

    <ImageView
        android:id="@+id/ivAppIcon"
        android:layout_width="40dp"
        android:layout_height="40dp"
        android:contentDescription="@null" />

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:orientation="vertical"
        android:layout_marginStart="12dp">

        <TextView
            android:id="@+id/tvAppName"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:textColor="@color/brand_on_surface"
            android:textSize="15sp"
            android:textStyle="bold" />

        <TextView
            android:id="@+id/tvPackageName"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:textColor="#A09FA5"
            android:textSize="11sp" />
    </LinearLayout>

    <com.google.android.material.checkbox.MaterialCheckBox
        android:id="@+id/cbBlocked"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content" />
</LinearLayout>
EOF

cat << 'EOF' > app/src/main/res/layout/item_domain_lock.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:gravity="center_vertical"
    android:padding="12dp">

    <ImageView
        android:layout_width="24dp"
        android:layout_height="24dp"
        android:src="@android:drawable/ic_menu_compass"
        android:contentDescription="@null" />

    <TextView
        android:id="@+id/tvDomainName"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:textColor="@color/brand_on_surface"
        android:textSize="14sp"
        android:layout_marginStart="12dp" />

    <ImageButton
        android:id="@+id/btnDeleteDomain"
        android:layout_width="36dp"
        android:layout_height="36dp"
        android:background="?attr/selectableItemBackgroundBorderless"
        android:src="@android:drawable/ic_menu_delete"
        android:contentDescription="Remover" />
</LinearLayout>
EOF

echo "[6/8] Gerando código Kotlin: Modelos e Aplicação..."

cat << 'EOF' > app/src/main/java/com/freedomlock/FreedomLockApp.kt
package com.freedomlock

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build

class FreedomLockApp : Application() {

    companion object {
        const val VPN_CHANNEL_ID = "freedom_lock_vpn_channel"
        const val ALERT_CHANNEL_ID = "freedom_lock_alert_channel"
        const val PREFS_NAME = "freedom_lock_preferences"
        const val KEY_BLOCKED_DOMAINS = "key_blocked_domains"
        const val KEY_BLOCKED_PACKAGES = "key_blocked_packages"
        const val KEY_VPN_ACTIVE = "key_vpn_active"

        fun getPreferences(context: Context): SharedPreferences {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java) ?: return

            val vpnChannel = NotificationChannel(
                VPN_CHANNEL_ID,
                "Serviço de Proteção VPN",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notificação persistente da filtragem DNS local."
                setShowBadge(false)
            }

            val alertChannel = NotificationChannel(
                ALERT_CHANNEL_ID,
                "Avisos de Bloqueio",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notificações informativas ao interceptar apps restritos."
                setShowBadge(true)
            }

            manager.createNotificationChannel(vpnChannel)
            manager.createNotificationChannel(alertChannel)
        }
    }
}
EOF

cat << 'EOF' > app/src/main/java/com/freedomlock/data/AppItem.kt
package com.freedomlock.data

import android.graphics.drawable.Drawable

data class AppItem(
    val name: String,
    val packageName: String,
    val icon: Drawable,
    var isBlocked: Boolean
)
EOF

echo "[7/8] Gerando código Kotlin: Serviços VPN e Acessibilidade..."

cat << 'EOF' > app/src/main/java/com/freedomlock/vpn/FreedomVpnService.kt
package com.freedomlock.vpn

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import com.freedomlock.FreedomLockApp
import com.freedomlock.R
import com.freedomlock.ui.MainActivity
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.SocketTimeoutException
import java.nio.ByteBuffer
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class FreedomVpnService : VpnService(), Runnable {

    companion object {
        const val ACTION_START = "com.freedomlock.vpn.START"
        const val ACTION_STOP = "com.freedomlock.vpn.STOP"
        private const val NOTIFICATION_ID = 4001
        private const val VPN_DNS_SERVER = "10.0.0.1"
        private const val UPSTREAM_DNS_PRIMARY = "1.1.1.1"
        private const val UPSTREAM_DNS_SECONDARY = "8.8.8.8"
        private const val DNS_PORT = 53

        @Volatile
        private var activeInstance: FreedomVpnService? = null

        fun isRunning(context: Context): Boolean {
            val instance = activeInstance
            val isTunnelActive = instance != null &&
                    instance.isRunning.get() &&
                    instance.vpnInterface?.fileDescriptor?.valid() == true &&
                    instance.vpnThread?.isAlive == true

            if (isTunnelActive) return true

            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            val activeNetwork = cm?.activeNetwork ?: return false
            val caps = cm.getNetworkCapabilities(activeNetwork) ?: return false

            return caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) && instance != null
        }
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private var vpnThread: Thread? = null
    private var dnsExecutor: ExecutorService? = null
    private val isRunning = AtomicBoolean(false)

    @Volatile
    private var blockedDomains: Set<String> = emptySet()

    private val preferenceListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key == FreedomLockApp.KEY_BLOCKED_DOMAINS) {
            reloadBlockedDomains()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopVpnService()
            return START_NOT_STICKY
        }
        startVpnService()
        return START_STICKY
    }

    private fun reloadBlockedDomains() {
        val prefs = FreedomLockApp.getPreferences(this)
        val loaded = prefs.getStringSet(FreedomLockApp.KEY_BLOCKED_DOMAINS, emptySet()) ?: emptySet()
        blockedDomains = loaded.map { it.trim().lowercase() }.filter { it.isNotEmpty() }.toSet()
    }

    private fun startVpnService() {
        if (isRunning.get()) return

        reloadBlockedDomains()
        FreedomLockApp.getPreferences(this).registerOnSharedPreferenceChangeListener(preferenceListener)

        val notification = createVpnNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        try {
            vpnInterface = Builder()
                .setSession("FreedomLockVpn")
                .setMtu(1500)
                .addAddress("10.0.0.2", 32)
                .addDnsServer(VPN_DNS_SERVER)
                .addRoute(VPN_DNS_SERVER, 32)
                .setBlocking(true)
                .establish()

            if (vpnInterface == null) {
                cleanupFailedStart()
                return
            }

            isRunning.set(true)
            activeInstance = this
            FreedomLockApp.getPreferences(this).edit().putBoolean(FreedomLockApp.KEY_VPN_ACTIVE, true).apply()

            val executor = Executors.newFixedThreadPool(4)
            dnsExecutor = executor
            vpnThread = Thread(this, "FreedomVpnThread").apply { start() }
        } catch (_: Exception) {
            cleanupFailedStart()
        }
    }

    private fun cleanupFailedStart() {
        isRunning.set(false)
        activeInstance = null

        try {
            FreedomLockApp.getPreferences(this).unregisterOnSharedPreferenceChangeListener(preferenceListener)
        } catch (_: Exception) {}

        dnsExecutor?.shutdownNow()
        dnsExecutor = null

        try {
            vpnThread?.interrupt()
            vpnInterface?.close()
        } catch (_: IOException) {}
        vpnInterface = null

        FreedomLockApp.getPreferences(this).edit().putBoolean(FreedomLockApp.KEY_VPN_ACTIVE, false).apply()

        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun stopVpnService() {
        cleanupFailedStart()
    }

    override fun onDestroy() {
        stopVpnService()
        super.onDestroy()
    }

    override fun run() {
        val descriptor = vpnInterface?.fileDescriptor ?: return
        val inputStream = FileInputStream(descriptor)
        val outputStream = FileOutputStream(descriptor)
        val readBuffer = ByteArray(32767)

        while (isRunning.get() && !Thread.currentThread().isInterrupted) {
            try {
                val bytesRead = inputStream.read(readBuffer)
                if (bytesRead > 0) {
                    val packetCopy = readBuffer.copyOf(bytesRead)
                    dnsExecutor?.execute {
                        processPacket(packetCopy, bytesRead, outputStream)
                    }
                }
            } catch (_: IOException) {
                break
            }
        }
    }

    private fun processPacket(packetData: ByteArray, bytesRead: Int, outputStream: FileOutputStream) {
        if (bytesRead < 28) return

        val versionAndIhl = packetData[0].toInt() and 0xFF
        if ((versionAndIhl ushr 4) != 4) return
        val ipHeaderLen = (versionAndIhl and 0x0F) * 4
        if (ipHeaderLen < 20 || bytesRead < ipHeaderLen + 8) return

        val protocol = packetData[9].toInt() and 0xFF
        if (protocol != 17) return

        val buffer = ByteBuffer.wrap(packetData, 0, bytesRead)
        val srcPort = buffer.getShort(ipHeaderLen).toInt() and 0xFFFF
        val dstPort = buffer.getShort(ipHeaderLen + 2).toInt() and 0xFFFF
        val udpLen = buffer.getShort(ipHeaderLen + 4).toInt() and 0xFFFF

        if (dstPort != DNS_PORT || udpLen < 8 || bytesRead < ipHeaderLen + udpLen) return

        val dnsLength = udpLen - 8
        if (dnsLength < 12) return

        val dnsOffset = ipHeaderLen + 8
        val dnsData = packetData.copyOfRange(dnsOffset, dnsOffset + dnsLength)
        val queriedDomain = parseDnsQuestionDomain(dnsData)

        val clientIp = packetData.copyOfRange(12, 16)
        val serverIp = packetData.copyOfRange(16, 20)

        if (queriedDomain != null && isDomainBlocked(queriedDomain)) {
            val nxPayload = buildNxDomainPayload(dnsData)
            val responsePacket = createIpv4UdpPacket(
                srcIp = serverIp,
                dstIp = clientIp,
                srcPort = dstPort,
                dstPort = srcPort,
                payload = nxPayload
            )
            synchronized(outputStream) {
                try { outputStream.write(responsePacket) } catch (_: IOException) {}
            }
        } else {
            forwardDnsPacket(clientIp, serverIp, srcPort, dstPort, dnsData, outputStream)
        }
    }

    private fun isDomainBlocked(domain: String): Boolean {
        val clean = domain.trim().lowercase()
        val currentSet = blockedDomains
        return currentSet.any { clean == it || clean.endsWith(".$it") }
    }

    private fun parseDnsQuestionDomain(dnsPayload: ByteArray): String? {
        try {
            if (dnsPayload.size < 12) return null
            var pos = 12
            val builder = StringBuilder()

            while (pos < dnsPayload.size) {
                val len = dnsPayload[pos].toInt() and 0xFF
                if (len == 0) break
                if ((len and 0xC0) != 0) return null
                pos++
                if (pos + len > dnsPayload.size) return null

                if (builder.isNotEmpty()) builder.append('.')
                builder.append(String(dnsPayload, pos, len, Charsets.US_ASCII))
                pos += len
            }
            return if (builder.isNotEmpty()) builder.toString() else null
        } catch (_: Exception) {
            return null
        }
    }

    private fun buildNxDomainPayload(queryDns: ByteArray): ByteArray {
        val response = queryDns.copyOf()
        response[2] = 0x81.toByte()
        response[3] = 0x83.toByte()
        response[6] = 0; response[7] = 0
        response[8] = 0; response[9] = 0
        response[10] = 0; response[11] = 0
        return response
    }

    private fun forwardDnsPacket(
        clientIp: ByteArray,
        serverIp: ByteArray,
        clientPort: Int,
        dnsPort: Int,
        dnsQuery: ByteArray,
        outputStream: FileOutputStream
    ) {
        val receivedDns = queryUpstream(dnsQuery, UPSTREAM_DNS_PRIMARY)
            ?: queryUpstream(dnsQuery, UPSTREAM_DNS_SECONDARY)

        if (receivedDns != null) {
            val responsePacket = createIpv4UdpPacket(
                srcIp = serverIp,
                dstIp = clientIp,
                srcPort = dnsPort,
                dstPort = clientPort,
                payload = receivedDns
            )
            synchronized(outputStream) {
                try { outputStream.write(responsePacket) } catch (_: IOException) {}
            }
        }
    }

    private fun queryUpstream(dnsQuery: ByteArray, serverAddress: String): ByteArray? {
        var socket: DatagramSocket? = null
        return try {
            socket = DatagramSocket()
            if (!protect(socket)) {
                socket.close()
                return null
            }
            socket.soTimeout = 1500

            val upstreamAddr = InetAddress.getByName(serverAddress)
            val outPacket = DatagramPacket(dnsQuery, dnsQuery.size, upstreamAddr, DNS_PORT)
            socket.send(outPacket)

            val inBuf = ByteArray(4096)
            val inPacket = DatagramPacket(inBuf, inBuf.size)
            socket.receive(inPacket)

            inPacket.data.copyOf(inPacket.length)
        } catch (_: SocketTimeoutException) {
            null
        } catch (_: Exception) {
            null
        } finally {
            socket?.close()
        }
    }

    private fun createIpv4UdpPacket(
        srcIp: ByteArray,
        dstIp: ByteArray,
        srcPort: Int,
        dstPort: Int,
        payload: ByteArray
    ): ByteArray {
        val totalLength = 28 + payload.size
        val packet = ByteArray(totalLength)
        val buf = ByteBuffer.wrap(packet)

        packet[0] = 0x45.toByte()
        packet[1] = 0.toByte()
        buf.putShort(2, totalLength.toShort())
        buf.putShort(4, 0.toShort())
        buf.putShort(6, 0x4000.toShort())
        packet[8] = 64.toByte()
        packet[9] = 17.toByte()
        System.arraycopy(srcIp, 0, packet, 12, 4)
        System.arraycopy(dstIp, 0, packet, 16, 4)
        recalculateIpv4Checksum(packet, 20)

        buf.putShort(20, srcPort.toShort())
        buf.putShort(22, dstPort.toShort())
        buf.putShort(24, (8 + payload.size).toShort())
        buf.putShort(26, 0.toShort())

        System.arraycopy(payload, 0, packet, 28, payload.size)
        return packet
    }

    private fun recalculateIpv4Checksum(packet: ByteArray, headerLength: Int) {
        packet[10] = 0
        packet[11] = 0
        var sum = 0
        var i = 0
        while (i < headerLength) {
            val high = packet[i].toInt() and 0xFF
            val low = packet[i + 1].toInt() and 0xFF
            sum += (high shl 8) or low
            i += 2
        }
        while (sum shr 16 != 0) {
            sum = (sum and 0xFFFF) + (sum shr 16)
        }
        val checksum = (sum.inv()) and 0xFFFF
        packet[10] = (checksum ushr 8).toByte()
        packet[11] = (checksum and 0xFF).toByte()
    }

    private fun createVpnNotification(): Notification {
        val launchIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, FreedomLockApp.VPN_CHANNEL_ID)
            .setContentTitle("Freedom Lock Ativo")
            .setContentText("Filtragem DNS e proteção local operando.")
            .setSmallIcon(R.drawable.ic_app_logo)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
}
EOF

cat << 'EOF' > app/src/main/java/com/freedomlock/service/AppMonitorAccessibilityService.kt
package com.freedomlock.service

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import com.freedomlock.FreedomLockApp
import com.freedomlock.ui.BlockScreenActivity

class AppMonitorAccessibilityService : AccessibilityService() {

    private var lastBlockedTime: Long = 0
    private var lastBlockedPackage: String? = null
    private val debounceThresholdMs = 1200L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val targetPackage = event.packageName?.toString() ?: return

        if (targetPackage == this.packageName || targetPackage == "com.android.systemui" || targetPackage == "android") {
            return
        }

        val prefs = FreedomLockApp.getPreferences(this)
        val blockedApps = prefs.getStringSet(FreedomLockApp.KEY_BLOCKED_PACKAGES, emptySet()) ?: emptySet()

        if (blockedApps.contains(targetPackage)) {
            val now = SystemClock.uptimeMillis()
            if (targetPackage == lastBlockedPackage && (now - lastBlockedTime) < debounceThresholdMs) {
                return
            }

            lastBlockedTime = now
            lastBlockedPackage = targetPackage

            performGlobalAction(GLOBAL_ACTION_HOME)

            val intent = Intent(this, BlockScreenActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra(BlockScreenActivity.EXTRA_BLOCKED_PACKAGE, targetPackage)
            }
            startActivity(intent)
        }
    }

    override fun onInterrupt() {
        lastBlockedPackage = null
    }
}
EOF

cat << 'EOF' > app/src/main/java/com/freedomlock/service/BootReceiver.kt
package com.freedomlock.service

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.os.UserManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.freedomlock.FreedomLockApp
import com.freedomlock.R
import com.freedomlock.ui.MainActivity
import com.freedomlock.vpn.FreedomVpnService

class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val RECOVERY_NOTIFICATION_ID = 5001

        private enum class StartFailureReason {
            VPN_NOT_PREPARED,
            SYSTEM_RESTRICTION_FGS
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val action = intent.action
        if (action != Intent.ACTION_BOOT_COMPLETED && action != Intent.ACTION_MY_PACKAGE_REPLACED) {
            return
        }

        val userManager = context.getSystemService(Context.USER_SERVICE) as? UserManager
        if (userManager != null && !userManager.isUserUnlocked) {
            return
        }

        val prefs = FreedomLockApp.getPreferences(context)
        val shouldBeActive = prefs.getBoolean(FreedomLockApp.KEY_VPN_ACTIVE, false)
        if (!shouldBeActive) {
            return
        }

        val prepareIntent = VpnService.prepare(context)
        if (prepareIntent != null) {
            prefs.edit().putBoolean(FreedomLockApp.KEY_VPN_ACTIVE, false).apply()
            notifyRecovery(context, StartFailureReason.VPN_NOT_PREPARED)
            return
        }

        if (FreedomVpnService.isRunning(context)) {
            return
        }

        try {
            val serviceIntent = Intent(context, FreedomVpnService::class.java).apply {
                this.action = FreedomVpnService.ACTION_START
            }
            ContextCompat.startForegroundService(context, serviceIntent)
        } catch (_: Exception) {
            notifyRecovery(context, StartFailureReason.SYSTEM_RESTRICTION_FGS)
        }
    }

    private fun notifyRecovery(context: Context, reason: StartFailureReason) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

        ensureNotificationChannel(manager)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val hasPermission = ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            if (!hasPermission) return
        }

        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return

        val (title, message) = when (reason) {
            StartFailureReason.VPN_NOT_PREPARED -> Pair(
                "Autorização de VPN necessária",
                "A proteção foi pausada porque a permissão de rede precisa ser renovada."
            )
            StartFailureReason.SYSTEM_RESTRICTION_FGS -> Pair(
                "Proteção pausada pelo sistema",
                "Dispositivo reiniciado. Toque para restaurar a proteção de bloqueio."
            )
        }

        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            context, 0, openIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(context, FreedomLockApp.ALERT_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setSmallIcon(R.drawable.ic_app_logo)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        try {
            manager.notify(RECOVERY_NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {}
    }

    private fun ensureNotificationChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (manager.getNotificationChannel(FreedomLockApp.ALERT_CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    FreedomLockApp.ALERT_CHANNEL_ID,
                    "Avisos de Bloqueio e Recuperação",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Alertas de reativação necessária e bloqueios em tempo real."
                    setShowBadge(true)
                }
                manager.createNotificationChannel(channel)
            }
        }
    }
}
EOF

echo "[8/8] Gerando código Kotlin: Telas e Adaptadores com exclusão única..."

cat << 'EOF' > app/src/main/java/com/freedomlock/ui/BlockScreenActivity.kt
package com.freedomlock.ui

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import com.freedomlock.R

class BlockScreenActivity : ComponentActivity() {

    companion object {
        const val EXTRA_BLOCKED_PACKAGE = "extra_blocked_package"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                returnToHomeScreen()
            }
        })

        val targetPackage = intent.getStringExtra(EXTRA_BLOCKED_PACKAGE) ?: ""
        renderDynamicLayout(targetPackage)
    }

    private fun renderDynamicLayout(targetPackage: String) {
        val rootLayout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            gravity = android.view.Gravity.CENTER
            setPadding(48, 48, 48, 48)
            setBackgroundColor(0xFF1E1E1E.toInt())
        }

        val iconView = ImageView(this).apply {
            val appIcon = try {
                packageManager.getApplicationIcon(targetPackage)
            } catch (_: PackageManager.NameNotFoundException) {
                getDrawable(R.drawable.ic_app_logo)
            }
            setImageDrawable(appIcon)
            layoutParams = android.widget.LinearLayout.LayoutParams(220, 220)
        }

        val appName = try {
            val info = packageManager.getApplicationInfo(targetPackage, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (_: PackageManager.NameNotFoundException) {
            "Aplicativo Restrito"
        }

        val titleView = TextView(this).apply {
            text = "Acesso Bloqueado"
            textSize = 22f
            setTextColor(0xFFFFFFFF.toInt())
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = android.view.Gravity.CENTER
            setPadding(0, 32, 0, 16)
        }

        val descView = TextView(this).apply {
            text = "O aplicativo \"$appName\" está restrito pelas regras ativas do Freedom Lock."
            textSize = 15f
            setTextColor(0xFFCCCCCC.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 48)
        }

        val homeButton = Button(this).apply {
            text = "Voltar ao Início"
            setOnClickListener { returnToHomeScreen() }
        }

        rootLayout.addView(iconView)
        rootLayout.addView(titleView)
        rootLayout.addView(descView)
        rootLayout.addView(homeButton)

        setContentView(rootLayout)
    }

    private fun returnToHomeScreen() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }
}
EOF

cat << 'EOF' > app/src/main/java/com/freedomlock/ui/AppListAdapter.kt
package com.freedomlock.ui

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.freedomlock.R
import com.freedomlock.data.AppItem
import com.google.android.material.checkbox.MaterialCheckBox

class AppListAdapter(
    private val appList: List<AppItem>,
    private val onToggleBlock: (String, Boolean) -> Unit
) : RecyclerView.Adapter<AppListAdapter.AppViewHolder>() {

    class AppViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val ivIcon: ImageView = view.findViewById(R.id.ivAppIcon)
        val tvName: TextView = view.findViewById(R.id.tvAppName)
        val tvPackage: TextView = view.findViewById(R.id.tvPackageName)
        val cbBlocked: MaterialCheckBox = view.findViewById(R.id.cbBlocked)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): AppViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_app_lock, parent, false)
        return AppViewHolder(view)
    }

    override fun onBindViewHolder(holder: AppViewHolder, position: Int) {
        val app = appList[position]
        holder.tvName.text = app.name
        holder.tvPackage.text = app.packageName
        holder.ivIcon.setImageDrawable(app.icon)

        holder.cbBlocked.setOnCheckedChangeListener(null)
        holder.cbBlocked.isChecked = app.isBlocked

        holder.cbBlocked.setOnCheckedChangeListener { _, isChecked ->
            app.isBlocked = isChecked
            onToggleBlock(app.packageName, isChecked)
        }

        holder.itemView.setOnClickListener {
            holder.cbBlocked.isChecked = !holder.cbBlocked.isChecked
        }
    }

    override fun getItemCount(): Int = appList.size
}
EOF

cat << 'EOF' > app/src/main/java/com/freedomlock/ui/DomainListAdapter.kt
package com.freedomlock.ui

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.freedomlock.R

class DomainListAdapter(
    private val domains: MutableList<String>,
    private val onListChanged: () -> Unit
) : RecyclerView.Adapter<DomainListAdapter.DomainViewHolder>() {

    class DomainViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val tvDomain: TextView = view.findViewById(R.id.tvDomainName)
        val btnDelete: ImageButton = view.findViewById(R.id.btnDeleteDomain)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DomainViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_domain_lock, parent, false)
        return DomainViewHolder(view)
    }

    override fun onBindViewHolder(holder: DomainViewHolder, position: Int) {
        val domain = domains[position]
        holder.tvDomain.text = domain
        holder.btnDelete.setOnClickListener {
            val currentPos = holder.bindingAdapterPosition
            if (currentPos != RecyclerView.NO_POSITION) {
                domains.removeAt(currentPos)
                notifyItemRemoved(currentPos)
                onListChanged()
            }
        }
    }

    override fun getItemCount(): Int = domains.size

    fun addDomain(domain: String) {
        if (!domains.contains(domain)) {
            domains.add(0, domain)
            notifyItemInserted(0)
            onListChanged()
        }
    }
}
EOF

cat << 'EOF' > app/src/main/java/com/freedomlock/ui/MainActivity.kt
package com.freedomlock.ui

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.View
import android.view.accessibility.AccessibilityManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.freedomlock.FreedomLockApp
import com.freedomlock.R
import com.freedomlock.data.AppItem
import com.freedomlock.service.AppMonitorAccessibilityService
import com.freedomlock.vpn.FreedomVpnService
import com.google.android.material.card.MaterialCardView
import com.google.android.material.materialswitch.MaterialSwitch
import com.google.android.material.tabs.TabLayout
import com.google.android.material.textfield.TextInputEditText
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : ComponentActivity() {

    private lateinit var tvVpnStatus: TextView
    private lateinit var switchVpn: MaterialSwitch
    private lateinit var cardAccessibility: MaterialCardView
    private lateinit var tvAccessibilityStatus: TextView
    private lateinit var tabLayout: TabLayout
    private lateinit var layoutApps: FrameLayout
    private lateinit var layoutDomains: LinearLayout
    private lateinit var progressApps: ProgressBar
    private lateinit var rvApps: RecyclerView
    private lateinit var etDomain: TextInputEditText
    private lateinit var btnAddDomain: Button
    private lateinit var rvDomains: RecyclerView

    private val blockedPackages = mutableSetOf<String>()
    private val blockedDomains = mutableListOf<String>()
    private lateinit var domainAdapter: DomainListAdapter

    private val vpnPrepareLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            startFreedomVpn()
        } else {
            switchVpn.isChecked = false
            Toast.makeText(this, "Autorização de VPN necessária.", Toast.LENGTH_SHORT).show()
        }
    }

    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) {}

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        initViews()
        loadPersistedData()
        setupListeners()
        setupTabs()
        setupDomainsList()
        loadInstalledApplications()
        checkNotificationPermission()
    }

    override fun onResume() {
        super.onResume()
        updateUiState()
    }

    private fun initViews() {
        tvVpnStatus = findViewById(R.id.tvVpnStatus)
        switchVpn = findViewById(R.id.switchVpn)
        cardAccessibility = findViewById(R.id.cardAccessibility)
        tvAccessibilityStatus = findViewById(R.id.tvAccessibilityStatus)
        tabLayout = findViewById(R.id.tabLayout)
        layoutApps = findViewById(R.id.layoutApps)
        layoutDomains = findViewById(R.id.layoutDomains)
        progressApps = findViewById(R.id.progressApps)
        rvApps = findViewById(R.id.rvApps)
        etDomain = findViewById(R.id.etDomain)
        btnAddDomain = findViewById(R.id.btnAddDomain)
        rvDomains = findViewById(R.id.rvDomains)
    }

    private fun loadPersistedData() {
        val prefs = FreedomLockApp.getPreferences(this)
        blockedPackages.clear()
        blockedPackages.addAll(prefs.getStringSet(FreedomLockApp.KEY_BLOCKED_PACKAGES, emptySet()) ?: emptySet())

        blockedDomains.clear()
        blockedDomains.addAll(prefs.getStringSet(FreedomLockApp.KEY_BLOCKED_DOMAINS, emptySet()) ?: emptySet())
    }

    private fun setupListeners() {
        switchVpn.setOnCheckedChangeListener { _, isChecked ->
            if (isChecked) {
                val prepareIntent = VpnService.prepare(this)
                if (prepareIntent != null) {
                    vpnPrepareLauncher.launch(prepareIntent)
                } else {
                    startFreedomVpn()
                }
            } else {
                stopFreedomVpn()
            }
        }

        cardAccessibility.setOnClickListener {
            if (!isAccessibilityServiceEnabled()) {
                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
            }
        }

        btnAddDomain.setOnClickListener {
            val domainText = etDomain.text?.toString()?.trim()?.lowercase() ?: ""
            if (domainText.isNotEmpty() && !blockedDomains.contains(domainText)) {
                domainAdapter.addDomain(domainText)
                etDomain.text?.clear()
            }
        }
    }

    private fun setupTabs() {
        tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabSelected(tab: TabLayout.Tab?) {
                when (tab?.position) {
                    0 -> {
                        layoutApps.visibility = View.VISIBLE
                        layoutDomains.visibility = View.GONE
                    }
                    1 -> {
                        layoutApps.visibility = View.GONE
                        layoutDomains.visibility = View.VISIBLE
                    }
                }
            }
            override fun onTabUnselected(tab: TabLayout.Tab?) {}
            override fun onTabReselected(tab: TabLayout.Tab?) {}
        })
    }

    private fun setupDomainsList() {
        domainAdapter = DomainListAdapter(blockedDomains) {
            saveBlockedDomains()
        }
        rvDomains.layoutManager = LinearLayoutManager(this)
        rvDomains.adapter = domainAdapter
    }

    private fun loadInstalledApplications() {
        lifecycleScope.launch(Dispatchers.IO) {
            val pm = packageManager
            val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
            val appItems = mutableListOf<AppItem>()

            for (app in apps) {
                if (pm.getLaunchIntentForPackage(app.packageName) != null && app.packageName != packageName) {
                    val name = pm.getApplicationLabel(app).toString()
                    val icon = pm.getApplicationIcon(app)
                    val isBlocked = blockedPackages.contains(app.packageName)
                    appItems.add(AppItem(name, app.packageName, icon, isBlocked))
                }
            }
            appItems.sortBy { it.name.lowercase() }

            withContext(Dispatchers.Main) {
                progressApps.visibility = View.GONE
                rvApps.visibility = View.VISIBLE
                rvApps.layoutManager = LinearLayoutManager(this@MainActivity)
                rvApps.adapter = AppListAdapter(appItems) { pkg, isBlocked ->
                    if (isBlocked) blockedPackages.add(pkg) else blockedPackages.remove(pkg)
                    saveBlockedPackages()
                }
            }
        }
    }

    private fun startFreedomVpn() {
        val serviceIntent = Intent(this, FreedomVpnService::class.java).apply {
            action = FreedomVpnService.ACTION_START
        }
        ContextCompat.startForegroundService(this, serviceIntent)
        updateUiState()
    }

    private fun stopFreedomVpn() {
        val serviceIntent = Intent(this, FreedomVpnService::class.java).apply {
            action = FreedomVpnService.ACTION_STOP
        }
        startService(serviceIntent)
        updateUiState()
    }

    private fun updateUiState() {
        val isVpnRunning = FreedomVpnService.isRunning(this)
        switchVpn.setOnCheckedChangeListener(null)
        switchVpn.isChecked = isVpnRunning
        switchVpn.setOnCheckedChangeListener { _, isChecked ->
            if (isChecked) startFreedomVpn() else stopFreedomVpn()
        }

        tvVpnStatus.text = if (isVpnRunning) getString(R.string.vpn_status_active) else getString(R.string.vpn_status_inactive)

        val isA11yActive = isAccessibilityServiceEnabled()
        tvAccessibilityStatus.text = if (isA11yActive) getString(R.string.accessibility_active) else getString(R.string.accessibility_inactive)
        tvAccessibilityStatus.setTextColor(ContextCompat.getColor(this, if (isA11yActive) R.color.status_active else R.color.status_inactive))
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as? AccessibilityManager ?: return false
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_GENERIC)
        val expected = "${packageName}/${AppMonitorAccessibilityService::class.java.name}"
        return enabledServices.any { it.id.equals(expected, ignoreCase = true) }
    }

    private fun saveBlockedPackages() {
        FreedomLockApp.getPreferences(this).edit().putStringSet(FreedomLockApp.KEY_BLOCKED_PACKAGES, blockedPackages).apply()
    }

    private fun saveBlockedDomains() {
        FreedomLockApp.getPreferences(this).edit().putStringSet(FreedomLockApp.KEY_BLOCKED_DOMAINS, blockedDomains.toSet()).apply()
    }

    private fun checkNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }
}
EOF

echo "[8/8] Estrutura do Freedom Lock gerada com sucesso!"
