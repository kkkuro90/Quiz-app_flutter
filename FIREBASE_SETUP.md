# Инструкция по настройке Firebase для Quiz App

## Текущее состояние
✅ **Authentication**: Email/Password включен  
✅ **Firestore Database**: Коллекция `quizzes` создана

## 1. Настройка правил безопасности Firestore

Перейдите в Firebase Console → Firestore Database → Rules и замените правила на следующие:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Функция проверки авторизации
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Функция проверки, что пользователь - владелец документа
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Функция получения роли пользователя
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }
    
    // Коллекция users - пользователи могут читать/писать только свой профиль
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }
    
    // Коллекция quizzes - учителя создают, все читают активные
    match /quizzes/{quizId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && getUserRole() == 'teacher';
      allow update: if isAuthenticated() && getUserRole() == 'teacher' && 
                     resource.data.ownerId == request.auth.uid;
      allow delete: if isAuthenticated() && getUserRole() == 'teacher' && 
                     resource.data.ownerId == request.auth.uid;
    }
    
    // Коллекция quiz_results - ученики создают свои результаты, учителя читают все
    match /quiz_results/{resultId} {
      allow read: if isAuthenticated() && (
        resource.data.studentId == request.auth.uid ||
        getUserRole() == 'teacher'
      );
      allow create: if isAuthenticated() && getUserRole() == 'student' &&
                     request.resource.data.studentId == request.auth.uid;
      allow update: if false; // Результаты нельзя изменять
      allow delete: if isAuthenticated() && getUserRole() == 'teacher';
    }
    
    // Коллекция grade_settings - только учителя
    match /grade_settings/{teacherId} {
      allow read: if isAuthenticated();
      allow create, update: if isAuthenticated() && 
                             getUserRole() == 'teacher' && 
                             teacherId == request.auth.uid;
      allow delete: if isAuthenticated() && getUserRole() == 'teacher' && 
                     teacherId == request.auth.uid;
    }
    
    // Коллекция schedule - только учителя
    match /schedule/{scheduleId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAuthenticated() && 
                                      getUserRole() == 'teacher' &&
                                      resource.data.teacherId == request.auth.uid;
    }
    
    // Коллекция study_materials - только учителя
    match /study_materials/{materialId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAuthenticated() && 
                                      getUserRole() == 'teacher' &&
                                      resource.data.teacherId == request.auth.uid;
    }
    
    // Коллекция notifications - пользователи читают только свои
    match /notifications/{notificationId} {
      allow read: if isAuthenticated() && 
                   resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && 
                     resource.data.userId == request.auth.uid;
      allow delete: if isAuthenticated() && 
                     resource.data.userId == request.auth.uid;
    }
    
    // Коллекция fcm_tokens - пользователи управляют только своими токенами
    match /fcm_tokens/{tokenId} {
      allow read, write: if isAuthenticated() && 
                          resource.data.userId == request.auth.uid;
    }
  }
}
```

**Важно**: После сохранения правил нажмите "Publish" для применения изменений.

---

## 2. Создание коллекций в Firestore

### 2.1. Коллекция `users`

**Путь**: `users/{userId}` (где `userId` = Firebase Auth UID)

**Структура документа**:
```
userId: string (документ ID)
email: string
role: string ("teacher" | "student")
name: string
createdAt: timestamp
updatedAt: timestamp
```

**Пример документа**:
```json
{
  "userId": "abc123xyz",
  "email": "teacher@example.com",
  "role": "teacher",
  "name": "Иван Иванов",
  "createdAt": "2024-12-12T10:00:00Z",
  "updatedAt": "2024-12-12T10:00:00Z"
}
```

**Как создать**: Коллекция создается автоматически при первой регистрации пользователя через приложение.

---

### 2.2. Коллекция `quizzes` (уже существует)

**Путь**: `quizzes/{quizId}`

**⚠️ ВАЖНО**: Проверьте, что в вашей коллекции используется поле `scheduledAt` (с "d"), а не `scheduleAt`. Если есть оба поля или только `scheduleAt`, удалите неправильное поле и используйте только `scheduledAt`.

**Структура документа**:
```
title: string
description: string
subject: string
questions: array [
  {
    id: string,
    text: string,
    type: number (0=singleChoice, 1=multipleChoice, 2=textAnswer),
    answers: array [
      {
        id: string,
        text: string,
        isCorrect: boolean
      }
    ],
    points: number,
    topic: string (опционально)
  }
]
duration: number (минуты)
scheduledAt: timestamp (опционально) ← ИСПРАВЬТЕ: было scheduleAt
isActive: boolean
ownerId: string (userId учителя)
pinCode: string (опционально)
```

**Примечание**: Убедитесь, что поле называется `scheduledAt`, а не `scheduleAt`.

---

### 2.3. Коллекция `quiz_results`

**Путь**: `quiz_results/{resultId}`

**Структура документа**:
```
quizId: string
studentId: string
studentName: string
totalPoints: number
maxPoints: number
percentage: number (0.0-1.0)
completedAt: timestamp
answers: array [
  {
    questionId: string,
    selectedAnswers: array[string],
    textAnswer: string (опционально),
    isCorrect: boolean,
    points: number,
    timeSpentSeconds: number (опционально)
  }
]
```

**Индексы** (создайте в Firestore → Indexes):
- **Composite Index 1**: `quizId` (Ascending) + `completedAt` (Descending)
- **Composite Index 2**: `studentId` (Ascending) + `completedAt` (Descending)

**Как создать индексы**:
1. Перейдите в Firestore → Indexes
2. Нажмите "Create Index"
3. Выберите коллекцию `quiz_results`
4. Добавьте поля:
   - `quizId` (Ascending)
   - `completedAt` (Descending)
5. Нажмите "Create"
6. Повторите для второго индекса с `studentId` и `completedAt`

---

### 2.4. Коллекция `grade_settings`

**Путь**: `grade_settings/{teacherId}` (где `teacherId` = userId учителя)

**Структура документа**:
```
teacherId: string (документ ID)
thresholds: map {
  "5": number (0.85 по умолчанию),
  "4": number (0.70 по умолчанию),
  "3": number (0.50 по умолчанию)
}
updatedAt: timestamp
```

**Пример документа**:
```json
{
  "teacherId": "teacher123",
  "thresholds": {
    "5": 0.85,
    "4": 0.70,
    "3": 0.50
  },
  "updatedAt": "2024-12-12T10:00:00Z"
}
```

---

### 2.5. Коллекция `schedule`

**Путь**: `schedule/{scheduleId}`

**Структура документа**:
```
teacherId: string
type: string ("quiz" | "task" | "material" | "reminder")
title: string
description: string
date: timestamp
durationMinutes: number (опционально)
relatedQuizId: string (опционально, если type = "quiz")
createdAt: timestamp
```

**Индексы**:
- **Composite Index**: `teacherId` (Ascending) + `date` (Ascending)

---

### 2.6. Коллекция `study_materials`

**Путь**: `study_materials/{materialId}`

**Структура документа**:
```
teacherId: string
subject: string
title: string
type: string ("lecture" | "presentation" | "document" | "video" | "homework")
format: string (например, "pdf", "docx", "mp4")
storagePath: string (URL в Firebase Storage)
sizeKb: number
updatedAt: timestamp
```

**Индексы**:
- **Composite Index**: `teacherId` (Ascending) + `subject` (Ascending)

---

### 2.7. Коллекция `notifications`

**Путь**: `notifications/{notificationId}`

**Структура документа**:
```
userId: string
title: string
message: string
type: string ("quiz" | "reminder" | "material" | "system")
isRead: boolean
createdAt: timestamp
```

**Индексы**:
- **Composite Index**: `userId` (Ascending) + `createdAt` (Descending)

---

### 2.8. Коллекция `fcm_tokens` (для push-уведомлений)

**Путь**: `fcm_tokens/{tokenId}`

**Структура документа**:
```
userId: string
token: string (FCM токен устройства)
deviceInfo: string (опционально)
createdAt: timestamp
updatedAt: timestamp
```

---

## 3. Настройка Firebase Storage (опционально, для файлов)

Если планируете загружать файлы (лекции, материалы):

1. Перейдите в Firebase Console → Storage
2. Нажмите "Get started"
3. Выберите режим: **Production mode** (или Test mode для разработки)
4. Нажмите "Next" → "Done"

### Правила безопасности Storage:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Папка для учебных материалов
    match /study_materials/{teacherId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                    request.auth.uid == teacherId;
    }
    
    // Общие правила (можно ограничить)
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 4. Проверка настройки

### Чеклист:

- [ ] Правила безопасности Firestore опубликованы
- [ ] Коллекция `users` будет создана автоматически при регистрации
- [ ] Коллекция `quizzes` существует (проверьте поле `scheduledAt`)
- [ ] Созданы индексы для `quiz_results` (2 индекса)
- [ ] Создан индекс для `schedule`
- [ ] Создан индекс для `study_materials`
- [ ] Создан индекс для `notifications`
- [ ] Firebase Storage настроен (если нужен)

---

## 5. Тестирование

После настройки протестируйте:

1. **Регистрация пользователя**:
   - Зарегистрируйте учителя (role: "teacher")
   - Зарегистрируйте ученика (role: "student")
   - Проверьте, что документы созданы в коллекции `users`

2. **Создание квиза**:
   - Войдите как учитель
   - Создайте квиз через приложение
   - Проверьте, что документ появился в `quizzes`

3. **Прохождение теста**:
   - Войдите как ученик
   - Пройдите тест
   - Проверьте, что результат сохранился в `quiz_results`

---

## 6. Частые проблемы

### Ошибка: "Missing or insufficient permissions"
- Проверьте правила безопасности Firestore
- Убедитесь, что пользователь авторизован
- Проверьте роль пользователя в коллекции `users`

### Ошибка: "The query requires an index"
- Перейдите по ссылке из ошибки в консоли
- Или создайте индекс вручную в Firestore → Indexes

### Коллекция не создается автоматически
- Firestore создает коллекции автоматически при первой записи
- Убедитесь, что правила безопасности разрешают запись

---

## Дополнительные ресурсы

- [Документация Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Документация Firestore Indexes](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Документация Firebase Storage](https://firebase.google.com/docs/storage)

