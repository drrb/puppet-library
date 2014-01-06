require 'spec_helper'

describe 'util' do
    describe Array do
        describe "#unique_by" do
            it "behaves like #uniq with a block, but works with Ruby < 1.9" do
                son = { "name" => "john", "age" => 10 }
                dad = { "name" => "john", "age" => 40 }
                mom = { "name" => "jane", "age" => 40 }

                family = [son, dad, mom]
                expect(family.unique_by {|p| p["name"]}).to eq [son, mom]
            end
        end
    end
end
