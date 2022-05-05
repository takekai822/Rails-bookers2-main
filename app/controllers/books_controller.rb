class BooksController < ApplicationController
  before_action :ensure_correct_user, only: [:update, :edit, :destroy]
  before_action :authenticate_user!

  def show
    @book = Book.find(params[:id])
    @book_new = Book.new
    @user = current_user
    @book_comment = BookComment.new
    unless ViewCount.find_by(user_id: current_user.id, book_id: @book.id)
      if @book.user != current_user
        current_user.view_counts.create(book_id: @book.id)
      end
    end
  end

  def index
    to  = Time.current.at_end_of_day
    from = (to - 6.day).at_beginning_of_day
    if params[:latest]
      @books = Book.latest
    elsif params[:star_count]
      @books = Book.star_count
    else
      @books = Book.includes(:favorited_users).
        sort {|a, b|
          b.favorited_users.includes(:favorites).where(created_at: from...to).size <=>
          a.favorited_users.includes(:favorites).where(created_at: from...to).size
        }
    end
    @book = Book.new
    @user = current_user
  end

  def create
    @book = Book.new(book_params)
    @book.user_id = current_user.id
    if @book.save
      redirect_to book_path(@book), notice: "You have created book successfully."
    else
      @user = current_user
      @books = Book.all
      render 'index'
    end
  end

  def edit
    @book = Book.find(params[:id])
    @user = current_user
  end

  def update
    @book = Book.find(params[:id])
    if @book.update(book_params)
      redirect_to book_path(@book), notice: "You have updated book successfully."
    else
      render "edit"
    end
  end

  def destroy
    @book = Book.find(params[:id])
    @book.destroy
    redirect_to books_path
  end

  private

  def book_params
    params.require(:book).permit(:title, :body, :star)
  end

  def ensure_correct_user
    @book = Book.find(params[:id])
    unless @book.user == current_user
      redirect_to books_path
    end
  end
end
