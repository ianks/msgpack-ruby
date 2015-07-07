require 'spec_helper'

describe MessagePack::Unpacker do
  class ValueOne
    def initialize(num)
      @num = num
    end
    def num
      @num
    end
    def to_msgpack_ext
      @num.to_msgpack
    end
    def self.from_msgpack_ext(data)
      self.new(MessagePack.unpack(data))
    end
  end

  class ValueTwo
    def initialize(num)
      @num_s = num.to_s
    end
    def num
      @num_s.to_i
    end
    def to_msgpack_ext
      @num_s.to_msgpack
    end
    def self.from_msgpack_ext(data)
      self.new(MessagePack.unpack(data))
    end
  end

  describe '#type_registered?' do
    it 'receive Class or Integer, and return bool' do
      expect(subject.type_registered?(0x00)).to be_falsy
      expect(subject.type_registered?(0x01)).to be_falsy
      expect(subject.type_registered?(::ValueOne)).to be_falsy
    end

    it 'returns true if specified type or class is already registered' do
      subject.register_type(0x30, ::ValueOne, :from_msgpack_ext)
      subject.register_type(0x31, ::ValueTwo, :from_msgpack_ext)

      expect(subject.type_registered?(0x00)).to be_falsy
      expect(subject.type_registered?(0x01)).to be_falsy

      expect(subject.type_registered?(0x30)).to be_truthy
      expect(subject.type_registered?(0x31)).to be_truthy
      expect(subject.type_registered?(::ValueOne)).to be_truthy
      expect(subject.type_registered?(::ValueTwo)).to be_truthy
    end

    it 'cannot detect unpack rule with block, not method' do
      subject.register_type(0x40){|data| ValueOne.from_msgpack_ext(data) }

      expect(subject.type_registered?(0x40)).to be_truthy
      expect(subject.type_registered?(ValueOne)).to be_falsy
    end
  end

  context 'with ext definitions' do
    it 'get type and class mapping for packing' do
      unpacker = MessagePack::Unpacker.new
      unpacker.register_type(0x01){|data| ValueOne.from_msgpack_ext }
      unpacker.register_type(0x02){|data| ValueTwo.from_msgpack_ext(data) }

      unpacker = MessagePack::Unpacker.new
      unpacker.register_type(0x01, ValueOne, :from_msgpack_ext)
      unpacker.register_type(0x02, ValueTwo, :from_msgpack_ext)
    end

    it 'returns a Hash which contains map of Class and type' do
      unpacker = MessagePack::Unpacker.new
      unpacker.register_type(0x01, ValueOne, :from_msgpack_ext)
      unpacker.register_type(0x02, ValueTwo, :from_msgpack_ext)

      expect(unpacker.registered_types).to be_a(Hash)
      expect(unpacker.registered_types.size).to eq(2)

      expect(unpacker.registered_types[0x01]).to eq(ValueOne.method(:from_msgpack_ext))
      expect(unpacker.registered_types[0x02]).to eq(ValueTwo.method(:from_msgpack_ext))
    end
  end
end
