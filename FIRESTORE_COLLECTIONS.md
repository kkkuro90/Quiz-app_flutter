# Required Firestore Collections for Quiz App

This document details the Firestore collections needed for the Quiz application to work properly.

## Collections Structure

### 1. `users` collection
Stores user information for both students and teachers

**Document structure:**
```
users/{userId}
```

**Fields:**
- `userId`: String (auto-generated document ID)
- `email`: String
- `name`: String
- `role`: String ("student" or "teacher")
- `createdAt`: Timestamp
- `updatedAt`: Timestamp

### 2. `quizzes` collection
Stores quiz information created by teachers

**Document structure:**
```
quizzes/{quizId}
```

**Fields:**
- `id`: String (auto-generated document ID)
- `title`: String
- `description`: String
- `subject`: String
- `questions`: Array of objects, each with:
  - `id`: String
  - `text`: String
  - `options`: Array of strings
  - `correctAnswer`: String or Array of strings (for multiple correct answers)
  - `topic`: String (optional)
- `duration`: Number (minutes)
- `isActive`: Boolean
- `pinCode`: String (4-digit PIN for student access)
- `teacherId`: String (ID of creator)
- `createdAt`: Timestamp
- `updatedAt`: Timestamp
- `scheduledAt`: Timestamp (optional, for scheduled quizzes)

### 3. `quiz_results` collection
Stores results when students complete quizzes

**Document structure:**
```
quiz_results/{resultId}
```

**Fields:**
- `id`: String (auto-generated document ID)
- `quizId`: String (ID of the quiz taken)
- `studentId`: String (ID of student who took quiz)
- `teacherId`: String (ID of quiz creator)
- `answers`: Array of objects, each with:
  - `questionId`: String
  - `selectedAnswers`: Array of strings
  - `isCorrect`: Boolean
  - `timeSpent`: Number (milliseconds, optional)
- `score`: Number (actual score)
- `percentage`: Number (0-1)
- `grade`: String ('5', '4', '3', '2', etc.)
- `completedAt`: Timestamp
- `totalTime`: Number (milliseconds spent on quiz)

### 4. `grade_settings` collection (optional, could be stored in user profile)
Stores grade thresholds customized by teachers

**Document structure:**
```
grade_settings/{teacherId}
```

**Fields:**
- `userId`: String (teacher ID)
- `gradeThresholds`: Map containing:
  - `5`: Number (threshold for grade 5, e.g., 0.9 for 90%)
  - `4`: Number (threshold for grade 4, e.g., 0.75 for 75%)
  - `3`: Number (threshold for grade 3, e.g., 0.6 for 60%)
  - `2`: Number (threshold for grade 2, e.g., 0.5 for 50%)

## Indexes Required

For proper querying, create these indexes in Firestore:

1. **Quizzes by active status:**
   - Collection: `quizzes`
   - Fields: `isActive` ascending, `pinCode` ascending

2. **Quiz results by quiz:**
   - Collection: `quiz_results`
   - Fields: `quizId` ascending, `completedAt` descending

3. **Quiz results by student:**
   - Collection: `quiz_results`
   - Fields: `studentId` ascending, `completedAt` descending

4. **Quizzes by scheduled date:**
   - Collection: `quizzes`
   - Fields: `scheduledAt` ascending, `isActive` ascending

## Sample Data

Here's an example of what data should look like in each collection:

### Sample User:
```
{
  "userId": "abc123def456",
  "email": "teacher@example.com",
  "name": "John Teacher",
  "role": "teacher",
  "createdAt": "2023-01-15T10:30:00Z",
  "updatedAt": "2023-01-15T10:30:00Z"
}
```

### Sample Quiz:
```
{
  "id": "xyz789uvw012",
  "title": "Mathematics Quiz",
  "description": "Test on algebra and geometry",
  "subject": "Mathematics",
  "questions": [
    {
      "id": "q1",
      "text": "What is 2+2?",
      "options": ["3", "4", "5", "6"],
      "correctAnswer": "4",
      "topic": "Basic Arithmetic"
    }
  ],
  "duration": 30,
  "isActive": true,
  "pinCode": "1234",
  "teacherId": "abc123def456",
  "createdAt": "2023-01-15T10:00:00Z",
  "scheduledAt": "2023-01-20T09:00:00Z"
}
```

### Sample Quiz Result:
```
{
  "id": "rst345opq678",
  "quizId": "xyz789uvw012",
  "studentId": "stu901vwx234",
  "teacherId": "abc123def456",
  "answers": [
    {
      "questionId": "q1",
      "selectedAnswers": ["4"],
      "isCorrect": true,
      "timeSpent": 15000
    }
  ],
  "score": 1,
  "percentage": 1.0,
  "grade": "5",
  "completedAt": "2023-01-20T09:15:00Z",
  "totalTime": 45000
}
```

## Security Rules for Firestore

In your `firestore.rules` file, you should have rules like:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own user data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow teachers to create quizzes, students can only read active ones
    match /quizzes/{quizId} {
      allow read: if request.auth != null && resource.data.isActive == true;
      allow write: if request.auth != null && request.auth.token.role == 'teacher';
    }
    
    // Allow students to create results, teachers can read all results for their quizzes
    match /quiz_results/{resultId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow read/write for grade_settings
    match /grade_settings/{teacherId} {
      allow read, write: if request.auth != null && request.auth.uid == teacherId;
    }
  }
}
```

## Setup Instructions

1. Create these collections in your Firestore database through the Firebase Console
2. Configure the indexes as specified above
3. Update your security rules
4. Make sure your app has the proper Firebase configuration files
5. Test that PIN code functionality and calendar notifications work properly