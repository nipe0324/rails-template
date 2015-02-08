# ソースファイルのパスを設定
def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end

# Railsのバージョン確認
unless `rails -v`.include?("Rails 4.2")
  puts "設定ファイルはRails 4.2をベースに作られているので、設定内容がデグレする可能性があります"
  exit
end

# 1. Railsプロジェクトの作成
# rspecを使うので、testディレクトリを削除
run 'rm -rf test'
# 不必要なファイルを削除
run "rm README.rdoc"

# 2. Gitにプロジェクトを登録
git :init
git add: '.'
git commit: %Q{ -m 'initial commit' }


# 3. 開発を効率化させるGemをがっつり導入

# 3.1. gemのインストール
gem 'jquery-turbolinks'

gem_group :development do
  # 開発を効率化する関連
  gem 'guard-livereload', require: false # ソースを修正するとブラウザが自動でロードされ、画面を作るときに便利
  gem 'rails-erd'                        # rake-erdコマンドでActiveRecordからER図を作成できる
  gem 'spring-commands-rspec'            # bin/rspecコマンドを使えるようにし、rspecの起動を早めれる
  gem 'bullet'                           # n+1問題を発見

  # 保守性を上げる
  gem 'rubocop', require: false          # コーディング規約の自動チェック
end

gem_group :development, :test do
  # pry関連(デバッグなど便利)
  gem 'pry-rails'    # rails cの対話式コンソールがirbの代わりにリッチなpryになる
  gem 'pry-doc'      # pry中に show-source [method名] でソース内を読める
  gem 'pry-byebug'   # binding.pryをソースに記載すると、ブレイクポイントとなりデバッグが可能になる
  gem 'pry-stack_explorer' # pry中にスタックを上がったり下がったり行き来できる

  # 表示整形関連(ログなど見やすくなる)
  gem 'hirb'         # モデルの出力結果を表形式で表示する
  gem 'hirb-unicode' # hirbの日本語などマルチバイト文字の出力時の出力結果がすれる問題に対応
  gem 'rails-flog', require: 'flog' # HashとSQLのログを見やすく整形
  gem 'better_errors'     # 開発中のエラー画面をリッチにする
  gem 'binding_of_caller' # 開発中のエラー画面にさらに変数の値を表示する
  gem 'awesome_print'     # Rubyオブジェクトに色をつけて表示して見やすくなる
  gem 'quiet_assets'      # ログのassetsを表示しないようにし、ログを見やすくしてくれる

  # テスト関連
  gem "rspec-rails"        # rspec本体
  gem "shoulda-matchers"   # モデルのテストを簡易にかけるmatcherが使える
  gem "factory_girl_rails" # テストデータ作成
  gem "capybara"           # エンドツーエンドテスト
  gem "capybara-webkit"    # エンドツーエンドテスト(javascript含む)
  gem 'launchy'            # capybaraのsave_and_open_pageメソッドの実行時に画面を開いてくれる
  gem "database_cleaner"   # エンドツーエンドテスト時のDBをクリーンにする
  gem "test-queue"         # テストを並列で実行する
  gem 'faker'              # 本物っぽいテストデータの作成
  gem 'faker-japanese'     # 本物っぽいテストデータの作成（日本語対応）
end

# gemをインストール
run 'bundle install'

# capybara-webkitがインストールできない場合
# Macだと次のコマンドでインストールをする
# $ brew update
# $ brew install qt4
# # コンソールを開き直す
# $ which qmake
# /usr/local/bin/qmake  # 何か出力されればインストールされていること

# 3.2. jquery-turbolinksの設定
run 'rm app/assets/javascripts/application.js'
copy_file 'files/application.js', 'app/assets/javascripts/application.js'


# 3.3. 開発を効率化する関連gemの設定
# gurard-livereloadのGuardfileを作成
run 'bundle exec guard init livereload'

# RSpecにSpringを追加する
run 'bin/spring stop'
run 'spring binstub --all'

# bulletを有効にする
run 'rm config/environments/development.rb'
copy_file 'files/development.rb', 'config/environments/development.rb'

# 3.5. 表示整形関連(ログなどを見やすくする)
copy_file 'files/.pryrc', '.pryrc'

# 3.6. テスト関連
generate 'rspec:install'
run 'rm spec/rails_helper.rb'
copy_file 'files/rails_helper.rb', 'spec/rails_helper.rb'
FileUtils.mkdir_p 'spec/support'
copy_file 'files/factory_girl.rb', 'spec/support/factory_girl.rb'
copy_file 'files/rspec-queue.rb', 'bin/rspec-queue'
run 'chmod 744 bin/rspec-queue'
run 'rm config/database.yml'
copy_file 'files/database.yml', 'config/database.yml'

# 4. 言語設定 / 5. タイムゾーン
run 'rm config/application.rb'
copy_file 'files/application.rb', 'config/application.rb'
copy_file 'files/ja.yml', 'config/locales/ja.yml'


# その他、必要に応じて
gem 'kaminari' # pagination
gem 'devise'   # Authentication
gem 'ransack'  # Search

gem_group :production do
  gem 'mysql2'
  gem 'unicorn'
end

# その他のgemをインストール
run 'bundle install'

# deviseの設定
if yes? 'use devise?'
  generate 'devise:install'
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }", env: 'development'
  generate 'controller Home index'
  route "root 'home#index'"
  copy_file 'files/devise.ja.yml', 'config/locales/devise.ja.yml'

  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate "devise", model_name
  rake 'db:migrate'
end

# オリジナルの簡易のスタイリング
if yes? 'use styling?'
  copy_file 'files/common.css.scss', 'app/assets/stylesheets/common.css.scss'
  styling = true
end

after_bundle do
  if styling
    puts "* Add below to 'application.html.erb'"
    puts ""
    puts '<body class=\'<%= "#{controller.controller_name}" %>\'>'
    puts '<div id="wrap">'
    puts '  <div id="main">'
    puts '    <%= yield %>'
    puts '  </div>'
    puts '</div>'
    puts '</body>'
  end
end
