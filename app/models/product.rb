#----------------------------------------------------------------------
# Product - 個々の機種に関する情報を操作
#----------------------------------------------------------------------
require_relative 'util'
class Product < Base

	# initialize - インスタンスを生成する
	#---------------------------------------------------------------------
	def initialize(id)
		@params = DB.new.get('product' , id)
	end

end
