# Инструкция по обновлению правил Firestore

## Полный код правил Firestore

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
      allow list: if isAuthenticated();  // Allow querying/reading lists
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

    // Коллекция quiz_sessions - для реального времени, пока разрешаем базовый доступ
    match /quiz_sessions/{sessionId} {
      allow read, write: if isAuthenticated();
    }
  }
}
```

## Как обновить правила через Firebase Console

### Шаг 1: Открытие Firebase Console
1. Перейдите на [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Войдите в ваш аккаунт Google
3. Найдите и выберите проект "quiz-app-3cd70"

### Шаг 2: Переход к Firestore Database
1. В левой боковой панели нажмите "Build"
2. Выберите "Firestore Database"

### Шаг 3: Обновление правил
1. Перейдите на вкладку "Rules" (рядом с вкладкой "Data")
2. Вы увидите текущие правила в текстовом редакторе
3. Выделите весь существующий код и удалите его
4. Вставьте код из раздела "Полный код правил Firestore" выше
5. Убедитесь, что весь код вставлен корректно

### Шаг 4: Сохранение изменений
1. Нажмите кнопку "Publish" (Опубликовать)
2. Подтвердите изменения, если появится диалог
3. Подождите, пока правила будут успешно опубликованы

## Ключевые изменения в правилах

### 1. Добавлено разрешение на запросы списков (list)
```javascript
allow list: if isAuthenticated();  // Allow querying/reading lists
```
- Разрешает аутентифицированным пользователям выполнять запросы типа `.where()` и `.get()`
- Решает проблему с поиском квизов по PIN-коду

### 2. Добавлены правила для коллекции quiz_sessions
```javascript
// Коллекция quiz_sessions - для реального времени, пока разрешаем базовый доступ
match /quiz_sessions/{sessionId} {
  allow read, write: if isAuthenticated();
}
```
- Разрешает аутентифицированным пользователям читать и записывать данные в реальном времени
- Используется для отслеживания состояния квизов и прогресса учеников

### 3. Сохранена безопасность
- Все операции по-прежнему требуют аутентификации
- Права на изменение и удаление ограничены по ролям (учитель/студент)
- Сохранены правила доступа к другим коллекциям

## После обновления правил

После публикации новых правил:
1. Перезапустите ваше Flutter-приложение
2. Проверьте функциональность PIN-кода и завершения квизов
3. Ошибки "Missing or insufficient permissions" больше не должны появляться