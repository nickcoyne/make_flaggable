class Flagging < ActiveRecord::Base

end

class FlaggableModel < ActiveRecord::Base
  make_flaggable :favorite, :inappropriate
end

class FlaggerModel < ActiveRecord::Base
  make_flagger
end

class InvalidFlaggableModel < ActiveRecord::Base
end
