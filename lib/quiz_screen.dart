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
    if (!_answered) return Colors.teal.shade900;
    final correct = _questions[_currentQuestionIndex].correctAnswer;
    if (answer == correct) return Colors.green.shade600;
    if (answer == _selectedAnswer) return Colors.red.shade600;
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;


    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading questions',style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _loadQuestions, child: const Text('Retry'),),
            ],
          ),
        ),
      );
    }
    if (_quizFinished) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Quiz Complete!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Score: $_score / ${_questions.length}',style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 32),
              ElevatedButton.icon(onPressed: _restartQuiz, icon: const Icon(Icons.refresh),label: const Text('Play Again'),),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trivia Quiz'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade300, color: Colors.teal[800]),
            const SizedBox(height: 8),
            Text('Question ${_currentQuestionIndex + 1} of ${_questions.length} | Score: $_score',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(_unescape.convert(question.question),style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),
            const SizedBox(height: 24),
            ...question.allAnswers.map((answer) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonColor(answer),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _answered ? null : () => _handleAnswer(answer),
                  child: Text(_unescape.convert(answer), textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                ),
              );
            }), 
            const Spacer(),
            if (_answered)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _nextQuestion,
                child: Text(
                  _currentQuestionIndex < _questions.length - 1 ? 'Next Question' : 'See Results',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}