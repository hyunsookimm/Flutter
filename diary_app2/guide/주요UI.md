# 주요 UI 설명

> 이 프로젝트에서 사용된 핵심 Flutter UI 컴포넌트 설명

---

## 1. Drawer (사이드 메뉴)

### 개념

`Drawer`는 화면 왼쪽에서 슬라이드해서 나오는 **사이드 네비게이션 패널**입니다.  
`Scaffold`의 `drawer` 속성에 등록하면 AppBar 햄버거 아이콘(`≡`)이 자동으로 생성됩니다.

### 기본 구조

```dart
Scaffold(
  appBar: AppBar(title: Text('내 일기장')),
  drawer: Drawer(               // ← 여기에 등록
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(...),      // 상단 헤더 영역
        ListTile(...),          // 메뉴 항목
        ListTile(...),
      ],
    ),
  ),
  body: ...,
)
```

### 프로젝트 적용 코드 (`home_page.dart`)

```dart
Widget _buildDrawer() {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,    // DrawerHeader가 상단 여백 없이 꽉 차도록
      children: [
        // ① 상단 헤더 (배경색 amber)
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.amber),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,  // 텍스트를 하단 정렬
            children: [
              Icon(Icons.menu_book, size: 48, color: Colors.white),
              SizedBox(height: 8),
              Text('내 일기장', style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // ② 메뉴 항목들
        ListTile(
          leading: const Icon(Icons.calendar_month),
          title: const Text('달력으로 보기'),
          onTap: () {
            Navigator.pop(context);          // Drawer 닫기
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const CalendarPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.search),
          title: const Text('일기 검색'),
          onTap: () {
            Navigator.pop(context);          // Drawer 닫기
            _startSearch();                  // 검색 모드 진입
          },
        ),
        // ... 추가 항목들
      ],
    ),
  );
}
```

### 핵심 포인트

| 항목 | 설명 |
|------|------|
| `padding: EdgeInsets.zero` | `ListView` 기본 상단 패딩을 제거해야 `DrawerHeader`가 상단에 딱 붙음 |
| `Navigator.pop(context)` | Drawer를 먼저 닫고 나서 페이지 이동해야 자연스러운 UX |
| `DrawerHeader` | 고정 높이(160px)의 헤더 영역. `decoration`으로 배경 처리 |
| `ListTile` | Drawer 메뉴의 표준 항목. `leading`(아이콘) + `title`(텍스트) 구성 |

### Drawer 열기/닫기 방법

```dart
// 코드에서 열기
Scaffold.of(context).openDrawer();

// 코드에서 닫기
Navigator.pop(context);

// 사용자가 직접: AppBar 햄버거 아이콘 탭 / 화면 왣쪽 끝에서 스와이프
```

---

## 2. Dismissible (스와이프 삭제)

### 개념

`Dismissible`은 리스트 항목을 **스와이프하면 사라지게** 만드는 위젯입니다.  
이메일 앱의 스와이프 삭제, 알림 지우기 등에서 흔히 보는 UX 패턴입니다.

### 기본 구조

```dart
Dismissible(
  key: Key('고유값'),          // ← 반드시 필요 (위젯 식별)
  direction: DismissDirection.endToStart,   // 오른쪽 → 왼쪽 스와이프
  background: Container(color: Colors.red), // 뒤에 보이는 배경
  onDismissed: (direction) {
    // 스와이프 완료 후 실행
    deleteItem();
  },
  child: ListTile(title: Text('항목')),
)
```

### 프로젝트 적용 코드 (`home_page.dart`)

```dart
Dismissible(
  key: Key(entry.path),                  // 파일 경로를 고유 키로 사용
  direction: DismissDirection.endToStart, // 왼쪽 스와이프만 허용

  // 스와이프 시 뒤에서 드러나는 빨간 배경
  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    decoration: BoxDecoration(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.delete, color: Colors.white, size: 28),
        Text('삭제', style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  ),

  // 실제로 삭제할지 확인 다이얼로그 (false 반환 시 취소)
  confirmDismiss: (_) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('일기 삭제'),
      content: Text('[$date] 일기를 삭제하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),  // 취소
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),   // 확인
          child: const Text('삭제', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  ),

  // confirmDismiss가 true를 반환했을 때만 실행
  onDismissed: (_) => _deleteSingle(entry.path),

  child: Card(
    child: ListTile(...),
  ),
)
```

### `confirmDismiss` vs `onDismissed` 차이

| 속성 | 실행 시점 | 반환값 | 역할 |
|------|----------|--------|------|
| `confirmDismiss` | 스와이프 후, 항목이 사라지기 전 | `Future<bool?>` | 삭제 여부 최종 확인 |
| `onDismissed` | `confirmDismiss`가 `true` 반환 후 | 없음 | 실제 삭제 로직 실행 |

> ⚠️ `confirmDismiss`에서 `false` 또는 `null`을 반환하면 항목이 **원위치**로 돌아옵니다.

### `key` 가 중요한 이유

```dart
// ❌ 잘못된 예 — 인덱스를 키로 사용
key: Key(index.toString())   // 삭제 후 다음 항목이 같은 키를 가져 오동작 가능

// ✅ 올바른 예 — 고유한 식별자를 키로 사용
key: Key(entry.path)         // 파일 경로는 항상 고유
```

### `DismissDirection` 옵션

```dart
DismissDirection.endToStart    // ← 왼쪽 스와이프 (오른쪽에서 왼쪽)
DismissDirection.startToEnd    // → 오른쪽 스와이프
DismissDirection.horizontal    // 양방향
DismissDirection.vertical      // 위아래
```

### 프로젝트에서의 흐름

```
사용자가 카드를 왼쪽으로 스와이프
         │
         ▼
  빨간 배경(삭제 아이콘) 노출
         │
         ▼
  confirmDismiss 실행 → AlertDialog 표시
         │
    ┌────┴────┐
  취소      삭제 확인
    │           │
  항목 복원   onDismissed 실행
              → _deleteSingle(path) 호출
              → 파일 삭제 + 목록 새로고침
```

---

## 3. ModalBottomSheet (달력 페이지 다중 일기 선택)

### 개념

화면 아래에서 올라오는 **반모달 패널**. 같은 날에 일기가 2개 이상일 때 선택지를 보여줄 때 사용합니다.

```dart
showModalBottomSheet(
  context: context,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (ctx) => Column(
    mainAxisSize: MainAxisSize.min,   // 내용 높이에만 맞춤
    children: [
      // 상단 핸들 바
      Container(width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2))),
      // 목록
      ListView.builder(shrinkWrap: true, ...),
    ],
  ),
);
```

### 핵심 포인트

| 속성 | 설명 |
|------|------|
| `mainAxisSize: MainAxisSize.min` | Column이 컨텐츠 높이에만 맞춰 줄어듦 |
| `shrinkWrap: true` | ListView가 Column 안에서 스크롤 없이 전체 높이 차지 |
| `shape` | 상단 모서리 둥근 처리 |

---

## 4. FloatingActionButton

### 개념

화면 우하단에 고정된 원형 버튼. 주요 액션(새 일기 쓰기)에 사용합니다.

```dart
// home_page.dart
floatingActionButton: _isMultiSelect
    ? null                               // 다중 선택 모드에서는 숨김
    : FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WritePage()),
          );
          _loadDiaries();                // 돌아온 후 목록 새로고침
        },
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        child: const Icon(Icons.edit),
      ),
```

---

## 5. BottomSheet (작성하기 버튼)

### 개념

`Scaffold.bottomSheet`에 위젯을 올리면 화면 하단에 **항상 고정된 영역**이 생깁니다.  
`showModalBottomSheet`와 달리 **올라오는 애니메이션 없이** 처음부터 고정 표시됩니다.

```dart
// write_page.dart / detail_page.dart
Scaffold(
  bottomSheet: SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.edit_note),
          label: const Text('작성하기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
        ),
      ),
    ),
  ),
  body: Padding(
    // bottomSheet 높이(약 80px)만큼 body 하단 패딩 추가
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
    ...
  ),
)
```

> ⚠️ `bottomSheet`를 사용하면 body가 버튼 뒤로 가려질 수 있으므로  
> body 하단 패딩을 버튼 높이만큼 추가해야 합니다.

### `SafeArea`를 감싸는 이유

iOS 홈 인디케이터(아이폰 하단 바) 등 시스템 UI와 겹치지 않도록 자동으로 여백을 추가합니다.
