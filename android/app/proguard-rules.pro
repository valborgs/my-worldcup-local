# --- Room / WorkManager (R8 full mode 대응) ---
# Room은 Class.forName("<DB클래스>_Impl") 후 기본 생성자로 인스턴스를 만든다.
# 의존성으로 끌려오는 room-runtime 2.2.5의 규칙은 클래스만 keep 하므로,
# R8 full mode에서 생성자가 제거되어 WorkDatabase 생성이 실패한다.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-dontwarn androidx.room.paging.**

# WorkManager가 androidx.startup으로 프로세스 시작 시 초기화하는 경로를 보존한다.
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
