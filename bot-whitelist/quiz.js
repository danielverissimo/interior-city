export function validateQuiz(quiz) {
  if (!Array.isArray(quiz?.questions) || quiz.questions.length === 0
    || !Number.isInteger(quiz.minimumPercentage) || quiz.minimumPercentage < 1
    || quiz.minimumPercentage > 100) {
    throw new Error('Confira as perguntas e a nota mínima em questionario.json.');
  }

  for (const question of quiz.questions) {
    if (typeof question?.prompt !== 'string' || !question.prompt.trim()
      || question.prompt.length > 500 || !Array.isArray(question.options)
      || question.options.length !== 3
      || question.options.some(option => typeof option !== 'string' || !option.trim() || option.length > 250)
      || !Number.isInteger(question.answer) || question.answer < 0 || question.answer >= question.options.length) {
      throw new Error('Há uma pergunta, alternativa ou gabarito inválido em questionario.json.');
    }
  }
  return quiz;
}

export function gradeQuiz(quiz, answers) {
  const score = quiz.questions.filter((question, index) => question.answer === answers[index]).length;
  const total = quiz.questions.length;
  const minimumScore = Math.ceil(total * quiz.minimumPercentage / 100);
  return { score, mistakes: total - score, percentage: score * 100 / total, minimumScore, approved: score >= minimumScore };
}
