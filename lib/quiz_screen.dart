import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'api_service.dart';
import 'question.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _apiService = ApiService();
  final HtmlUnescape _unescape= HtmlUnescape();

  List<Question> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedAnswer;
  bool _quizFinished = false;



  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final questions = await _apiService.fetchQuestions();
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleAnswer(String selected) {
    if (_answered) return;
    final correct=_questions[_currentQuestionIndex].correctAnswer;

    setState(() {
      _answered = true;
      _selectedAnswer = selected;
      if (selected == correct) _score++;
    });
  }
  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answered = false;
        _selectedAnswer = null;
      });
    } else {
      setState(() {
        _quizFinished = true;
      });
    }
  }
  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _answered = false;
      _selectedAnswer = null;
      _quizFinished = false;
    });
    _loadQuestions();
  }
  
  Color _buttonColor(String answer) {
    if (!_answered) return Colors.indigo.shade600;
    final correct = _questions[_currentQuestionIndex].correctAnswer;
    if (answer == correct) return Colors.green.shade600;
    if (answer == _selectedAnswer) return Colors.red.shade600;
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestionIndex];


    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return const Scaffold(
        body: Center(child: Text('Error loading questions')),
      );
    }
    if (_quizFinished) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Quiz Complete!'),
              Text('Score: $_score / ${_questions.length}'),
              ElevatedButton(onPressed: _restartQuiz, child: const Text('Play Again'),),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trivia Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(question.question, style: const TextStyle(fontSize: 20),),
            const SizedBox(height: 20),
            ...question.allAnswers.map((answer) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  onPressed: _answered ? null : () => _handleAnswer(answer),
                  child: Text(answer),
                ),
              );
            }),
            const Spacer(),
            if (_answered)
              ElevatedButton(
                onPressed: _nextQuestion,
                child: Text(
                  _currentQuestionIndex < _questions.length - 1 ? 'Next Question' : 'See Results',
                ),
              ),
          ],
        ),
      ),
    );
  }
}