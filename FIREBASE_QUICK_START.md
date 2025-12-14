# Firebase - Быстрый старт

## Шаг 1: Правила безопасности Firestore

Firebase Console → Firestore Database → Rules → Вставьте правила из `FIREBASE_SETUP.md` → Publish

## Шаг 2: Проверка коллекции quizzes

Убедитесь, что поле называется `scheduledAt` (не `scheduleAt`). Если есть `scheduleAt`, удалите его.

## Шаг 3: Коллекции создаются автоматически

Следующие коллекции создадутся автоматически при первом использовании:
- `users` - при регистрации пользователя
- `quiz_results` - при прохождении теста
- `grade_settings` - при сохранении настроек оценок
- `schedule` - при добавлении события в календарь
- `study_materials` - при загрузке материала
- `notifications` - при создании уведомления

## Шаг 4: Создание индексов (обязательно!)

Firestore → Indexes → Create Index:

1. **quiz_results**:
   - Collection: `quiz_results`
   - Fields: `quizId` (Ascending) + `completedAt` (Descending)
   
2. **quiz_results** (второй):
   - Collection: `quiz_results`
   - Fields: `studentId` (Ascending) + `completedAt` (Descending)

3. **schedule**:
   - Collection: `schedule`
   - Fields: `teacherId` (Ascending) + `date` (Ascending)

4. **study_materials**:
   - Collection: `study_materials`
   - Fields: `teacherId` (Ascending) + `subject` (Ascending)

5. **notifications**:
   - Collection: `notifications`
   - Fields: `userId` (Ascending) + `createdAt` (Descending)

## Готово! 🎉

Теперь можно тестировать регистрацию и создание квизов.

**Подробная инструкция**: см. `FIREBASE_SETUP.md`

