class Dog

   attr_accessor :id

   def initialize(args)
      @id = nil
      args.keys.each do |key|
         self.class.attr_accessor(key)
         self.send("#{key}=", args[key])
      end
   end

   def self.create_table
      sql = <<-SQL
         CREATE TABLE IF NOT EXISTS dogs (
            id INTEGER PRIMARY KEY,
            name TEXT,
            breed TEXT
         )
      SQL
      DB[:conn].execute(sql)
   end

   def self.drop_table
      sql = <<-SQL
         DROP TABLE IF EXISTS dogs
      SQL
      DB[:conn].execute(sql)
   end

   def save
      if @id   # if already exists, update in db
         self.update
      else     # if new, insert new into db
         sql = <<-SQL
            INSERT INTO dogs (name, breed) VALUES (?, ?)
         SQL
         DB[:conn].execute(sql, @name, @breed)
         self.id = DB[:conn].execute("SELECT id FROM dogs WHERE name=? AND breed=? LIMIT 1", @name, @breed)[0][0]
      end
      self
   end

   def self.create (args)
      dog = Dog.new(args)
      dog.save
   end

   def self.new_from_db(row)
      Dog.new(id: row[0], name: row[1], breed: row[2])
   end

   def self.all
      sql = <<-SQL
         SELECT *
         FROM dogs
      SQL
      DB[:conn].execute(sql).map {|row| self.new_from_db(row)}
   end

   def self.find_by_name(name)
      sql = <<-SQL
         SELECT *
         FROM dogs
         WHERE name=?
         LIMIT 1
      SQL
      DB[:conn].execute(sql, name).map {|row| self.new_from_db(row)}[0]
   end

   def self.find(id)
      sql = <<-SQL
         SELECT *
         FROM dogs
         WHERE id=?
         LIMIT 1
      SQL
      DB[:conn].execute(sql, id).map do |row|
         self.new_from_db(row)
      end.first
   end

   def self.find_or_create_by(name:, breed:)
      sql = <<-SQL
         SELECT *
         FROM dogs
         WHERE
            name=?
            AND breed=?
      SQL
      result = DB[:conn].execute(sql, name, breed)[0]
      if result
         self.new_from_db(result)
      else
         self.create(name: name, breed: breed)
      end
   end

   def update
      sql = <<-SQL
         UPDATE dogs
         SET
            name=?,
            breed=?
         WHERE id=?
      SQL
      DB[:conn].execute(sql, @name, @breed, @id)
   end

end
