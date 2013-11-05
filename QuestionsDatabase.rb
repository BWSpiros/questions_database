require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super("questions.db")

    self.results_as_hash = true
    self.type_translation = true
  end
end

class DatabaseThings
  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute("SELECT * FROM #{self.to_s.downcase}s WHERE id = #{id}")
    results.map { |result| self.new(result) }
  end

  def self.find_things_by_thing(col, val)
    results = QuestionsDatabase.instance.execute(
    "SELECT * FROM #{self.to_s.downcase}s WHERE #{col} = '#{val}'")
    results.map { |result| self.new(result) }
  end

end

class User < DatabaseThings
  def self.all
    results = QuestionsDatabase.instance.execute("SELECT * FROM users")
    results.map { |result| User.new(result) }
  end

  def self.find_by_name(fname, lname)
    result = QuestionsDatabase.instance.execute("SELECT * FROM users WHERE fname = #{fname} AND lname=#{lname}")
    User.new(result)
  end

  attr_accessor :id, :fname, :lname

  def initialize(options = {})
    @id = options["id"]
    @fname = options["fname"]
    @lname = options["lname"]
  end

  def create
    raise "already saved!" unless self.id.nil?

    QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      INSERT INTO
        questions (fname, lname)
      VALUES
        (?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def authored_questions
    Question.find_by_author_id(self.id)
  end

  def authored_replies
    Replie.find_by_user_id(self.id)
  end

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(self.id)
  end
end

class Question < DatabaseThings
  def self.all
    results = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    results.map { |result| Question.new(result) }
  end

  def self.find_by_author_id(auth_id)
    find_things_by_thing("author", auth_id)
  end

  def self.most_followed(n)
    Question_Follower.most_followed_questions(n)
  end

  def self.most_liked(n)
    Question_Like.most_liked_questions(n)
  end

  attr_accessor :id, :title, :body, :author_id

  def initialize(options = {})
    @id = options["id"]
    @title = options["title"]
    @body = options["body"]
    @author_id = options["author"]
  end

  def create
    raise "already saved!" unless self.id.nil?

    QuestionsDatabase.instance.execute(<<-SQL, title, body, author)
      INSERT INTO
        questions (title, body, author)
      VALUES
        (?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def author
    User.find_by_id(@author_id)[0]
  end

  def replies
    Replie.find_by_question_id(self.id)
  end

  def followers
    QuestionFollower.followers_for_question_id(self.id)
  end
end

class Question_Follower < DatabaseThings
  def self.all
    results = QuestionsDatabase.instance.execute("SELECT * FROM question_followers")
    results.map { |result| Question_Follower.new(result) }
  end

  def self.followers_for_question_id(id)
    results = QuestionsDatabase.instance.execute("SELECT * FROM users JOIN
    question_followers ON users.id = question_followers.user_id
    WHERE #{id} = question_followers.question_id")
    results.map { |result| Question_Follower.new(result) }
  end

  def self.followed_questions_for_user_id(id)
    results = QuestionsDatabase.instance.execute("SELECT * FROM questions
    JOIN question_followers ON questions.id = question_followers.question_id
    WHERE #{id} = question_followers.user_id")
    results.map { |result| Question_Follower.new(result) }
  end

  def self.most_followed_questions(n)
    results = QuestionsDatabase.instance.execute("SELECT *, COUNT(*) FROM questions
    JOIN question_followers ON questions.id = question_followers.question_id
    GROUP BY questions.id ORDER BY COUNT(*) DESC LIMIT #{n}")
    results.map { |result| Question_Follower.new(result) }
  end

  attr_accessor :id, :question_id, :user_id

  def initialize(options = {})
    @id = options["id"]
    @question_id = options["question_id"]
    @user_id = options["user_id"]
  end

  def create
    raise "already saved!" unless self.id.nil?

    QuestionsDatabase.instance.execute(<<-SQL, question_id, user_id)
      INSERT INTO
        questions (question_id, user_id)
      VALUES
        (?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end
end

class Replie < DatabaseThings
  def self.all
    results = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    results.map { |result| Replie.new(result) }
  end

  def self.find_by_question_id(question_id)
    self.find_things_by_thing("question", question_id)
  end

  def self.find_by_user_id(user_id)
    self.find_things_by_thing("user", user_id)
  end

  attr_accessor :id, :body, :parent, :question, :user

  def initialize(options = {})
    @id = options["id"]
    @body = options["body"]
    @parent = options["parent"]
    @question = options["question"]
    @user = options["user"]
  end

  def create
    raise "already saved!" unless self.id.nil?

    QuestionsDatabase.instance.execute(<<-SQL, body, parent, question, user)
      INSERT INTO
        questions (body, parent, question, user)
      VALUES
        (?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def author
    User.find_by_id(user)
  end

  def question
    Question.find_by_id(@question)
  end

  def parent_replie
    return nil if @parent.nil?
    Replie.find_by_id(@parent)
  end

  def child_replies
    Replie.find_things_by_thing("parent", self.id)
  end
end

class Question_Like < DatabaseThings
  def self.all
    results = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    results.map { |result| Question_Like.new(result) }
  end

  def self.likers_for_question_id(id)
    results = QuestionsDatabase.instance.execute("SELECT users.* FROM users JOIN
    question_likes ON users.id = question_likes.user_id
    WHERE #{id} = question_likes.question_id")
    results.map { |result| User.new(result) }
  end

  def self.num_likes_for_question_id(id)
    results = QuestionsDatabase.instance.execute("SELECT users.* FROM users JOIN
    question_likes ON users.id = question_likes.user_id
    WHERE #{id} = question_likes.question_id")
    results.first.values.first
  end

  def self.liked_questions_for_user_id(id)
    results = QuestionsDatabase.instance.execute("SELECT questions.*
    FROM questions JOIN question_likes ON questions.id = question_likes.question_id
    WHERE #{id} = question_likes.user_id")
    results.map { |result| Question.new(result) }
  end

  def self.most_liked_questions(n)
    results = QuestionsDatabase.instance.execute("SELECT questions.*, COUNT(*) FROM questions
    JOIN question_likes ON questions.id = question_likes.question_id
    GROUP BY questions.id ORDER BY COUNT(*) DESC LIMIT #{n}")
    results.map { |result| Question.new(result) }
  end

  attr_accessor :id, :likes, :user, :question

  def initialize(options = {})
    @id = options["id"]
    @likes = options ["likes"]
    @question = options["question"]
    @user = options["user"]
  end

  def create
    raise "already saved!" unless self.id.nil?

    QuestionsDatabase.instance.execute(<<-SQL, body, parent, question, user)
      INSERT INTO
        questions (body, parent, question, user)
      VALUES
        (?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end
end