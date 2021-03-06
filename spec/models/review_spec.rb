require 'rails_helper'

RSpec.describe Review, type: :model do

  context "必須チェック" do
    it "題名とレビューコメント、使用目的があれば有効な状態であること" do
      review = FactoryBot.build(:review)
      review.valid?
      expect(review).to be_valid
    end

    it "titleがなければ無効な状態であること" do
      review = FactoryBot.build(:review, :without_title)
      review.valid?(:publish)
    
      expect(review.errors[:title]).to include("を入力してください")
    end

    it "bodyがなければ無効な状態であること" do
      review = FactoryBot.build(:review, :without_body)
      review.valid?(:publish)

      expect(review.errors[:body]).to include("を入力してください")
    end
  end

  context "下書きの場合、必須チェックが行われないこと" do
    it "題名とレビューコメントが無効な状態で登録できること" do
      review = FactoryBot.build(:review, :draft)
      review.valid?
      expect(review).to be_valid
    end

    it "titleがなくても有効な状態であること" do
      review = FactoryBot.build(:review, :without_title, :without_body, :draft)
      review.valid?
    
      expect(review.errors[:title]).to_not include("を入力してください")
    end

    it "bodyがなくても有効な状態であること" do
      review = FactoryBot.build(:review, :draft)
      review.valid?

      expect(review.errors[:body]).to_not include("を入力してください")
    end
  end

  context "入力値チェック" do
    it "titleにカンマを含む場合、無効な状態であること" do
      review = FactoryBot.build(:review, :title_include_comma)
      review.valid?

      expect(review.errors[:title]).to include("にカンマを含めることはできません")
    end

    it "bodyにカンマを含む場合、無効な状態であること" do
      review = FactoryBot.build(:review, :body_include_comma)
      review.valid?

      expect(review.errors[:body]).to include("にカンマを含めることはできません")
    end

    it "titleが最大文字列（#{Review::TITLE_MAX_LENGTH}）以上の場合、無効な状態であること" do
      review = FactoryBot.build(:review, :title_max_over)
      review.valid?

      expect(review.errors[:title]).to include("は#{ Review::TITLE_MAX_LENGTH }文字以内で入力してください")
    end

    it "bodyが最大文字列（#{Review::BODY_MAX_LENGTH}）以上の場合、無効な状態であること" do
      review = FactoryBot.build(:review, :body_max_over)
      review.valid?

      expect(review.errors[:body]).to include("は#{ Review::BODY_MAX_LENGTH }文字以内で入力してください")
    end
  end

  context "重複チェック" do
    it "すでに同一車種でレビューが投稿されていた場合、無効な状態であること" do
      review = FactoryBot.create(:review)
      other_review = FactoryBot.build(:review, user: review.user, vehicle: review.vehicle)
      other_review.valid?

      expect(other_review.errors[:base]).to include("すでに同一車種でレビューが投稿されています。投稿日:#{review.created_at.to_date}")
    end
  end

  context "検索(search)が行えること" do

    before do
      @review1 = FactoryBot.create(:review, title: 'ツーリングにもってこい')
      @review2 = FactoryBot.create(:review_2, body: 'デザイン性が革新的')
      @review3 = FactoryBot.create(:review_3, title: '扱いやすい', body: '作りがチープ')
    end

    it "titleとbodyで検索した場合、該当するレビューがヒットすること" do
      expect(Review.search(0, search: 'ツーリングにもってこい デザイン性が革新的')).to include(@review1, @review2)
    end

    it "titleとbodyで検索した場合、該当しないレビューがヒットしないこと" do
      expect(Review.search(0, search: 'ツーリングにもってこい デザイン性が革新的')).to_not include(@review3)
    end

    it "vehicle_idを指定した場合、該当するレビューがヒットすること" do
      expect(Review.search(0, vehicle_id: @review3.vehicle_id)).to include(@review3)
    end

    it "vehicle_idを指定した場合、該当しないレビューがヒットしないこと" do
      expect(Review.search(0, vehicle_id: @review3.vehicle_id)).to_not include(@review1, @review2)
    end
  end
end

context "関連ＤＢが削除されること" do
  it "reviewを削除すると、like(参考になった)も削除されること" do
    user = FactoryBot.create(:user)
    review = FactoryBot.create(:review, user: user)
    Like.create(user_id: user.id, review_id: review.id)

    expect{ review.destroy }.to change{ Like.count }.by(-1)
  end
end

context "Active Storage" do

  after do
    @review.image.purge
  end

  it "レビュー画像が登録できること" do
    @review = FactoryBot.create(:review_4)
    expect(@review.image.attached?).to be true
  end

  it "レビュー画像が更新できること" do
    @review = FactoryBot.create(:review)
    @review.image.attach(io: File.open(Rails.root.join('spec', 'factories', 'images', 'test.jpg').to_s), filename: 'test.jpg', content_type: 'image/jpg')
    expect(@review.image.attached?).to be true
  end

  it "レビュー画像が削除できること" do
    @review = FactoryBot.create(:review_4)
    @review.image.purge
    expect(@review.image.attached?).to be false
  end
end