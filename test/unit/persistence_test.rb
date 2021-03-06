require 'test_helper'

class PersistenceTest < Test::Unit::TestCase
  include Apotomo::TestCaseMethods::TestController
  
  class PersistentMouse < Apotomo::StatefulWidget # we need a named class for marshalling.
    attr_reader :who, :what
      
    def educate
      @who  = "the cat"
      @what = "run away"
      render :nothing => true
    end
      
    def recap;  render :nothing => true; end
  end
  
  def stateless(name)
    Apotomo::Widget.new(parent_controller, name, :eat)
  end
  
  def stateful(name)
    PersistentMouse.new(parent_controller, name, :educate)
  end
  
  context "StatefulWidget" do
  
    context ".stateful_branches_for" do
      should "provide all stateful branch-roots seen from root" do
        @root = stateless('root')
        @root << mum_and_kid!
        @root << stateless('berry') << @jerry = mouse_mock('jerry', :eat)
        
        assert_equal ['mum', 'jerry'], Apotomo::StatefulWidget.stateful_branches_for(@root).collect {|n| n.name}
      end
    end
  end
  
  context "freezing and thawing a widget family" do
    setup do
      mum_and_kid!
      @storage = {}
    end
    
    context "and calling #flush_storage" do
      should "clear the storage from frozen data" do
        @root = stateless('root')
        @root << @mum
          
        Apotomo::StatefulWidget.freeze_for(@storage, @root)
        
        assert @storage[:apotomo_stateful_branches]
        assert @storage[:apotomo_widget_ivars]
        
        Apotomo::StatefulWidget.flush_storage(@storage)
        
        assert_nil @storage[:apotomo_stateful_branches]
        assert_nil @storage[:apotomo_widget_ivars]
      end
    end
    
    should "push @mum's freezable ivars to the storage when calling #freeze_ivars_to" do
      @mum.freeze_ivars_to(@storage)
      
      assert_equal 1, @storage.size
      assert_equal 6, @storage['mum'].size
    end
    
    should "push family's freezable ivars to the storage when calling #freeze_data_to" do
      @kid << mouse_mock('pet')
      @mum.freeze_data_to(@storage)
      
      assert_equal 3, @storage.size
      assert_equal 6, @storage['mum'].size
      assert_equal 6, @storage['mum/kid'].size
      assert_equal 5, @storage['mum/kid/pet'].size
    end
    
    should "push ivars and structure to the storage when calling #freeze_to" do
      @mum.freeze_to(@storage)
      assert_equal 2, @storage[:apotomo_widget_ivars].size
      assert_kind_of Apotomo::StatefulWidget, @storage[:apotomo_root]
    end
    
    context "that has also stateless widgets" do
      setup do
        @root = stateless('root')
          @root << mum_and_kid!
          @root << stateless('berry') << @jerry = mouse_mock('jerry', :eat)
        @root << stateless('tom')
        
        Apotomo::StatefulWidget.freeze_for(@storage, @root)
      end
      
      should "ignore stateless widgets when calling #freeze_for" do
        assert_equal(['root/mum', 'root/mum/kid', "root/berry/jerry"], @storage[:apotomo_widget_ivars].keys)
      end
      
      should "save stateful branches only" do
        assert_equal([[[MouseCell, 'mum', 'root'], [MouseCell, 'kid', 'mum']], [[MouseCell, 'jerry', 'berry']]], @storage[:apotomo_stateful_branches])
      end
      
      should "attach stateful branches to the tree in thaw_for" do
        @new_root = stateless('root')
          @new_root << stateless('berry')
        assert_equal @new_root, Apotomo::StatefulWidget.thaw_for(@controller, @storage, @new_root)
        
        assert_equal 5, @new_root.size  # without tom.
      end
      
      should "re-establish ivars recursivly when calling #thaw_for" do
        @storage[:apotomo_stateful_branches] = Marshal.load(Marshal.dump(@storage[:apotomo_stateful_branches]))
        
        @new_root = stateless('root')
          @new_root << stateless('berry')
        @new_root = Apotomo::StatefulWidget.thaw_for(@controller, @storage, @new_root)
        
        assert_equal :answer_squeak,  @new_root['mum'].instance_variable_get(:@start_state)
        assert_equal :peek,           @new_root['mum']['kid'].instance_variable_get(:@start_state)
      end
      
      should "raise an exception when thaw_for can't find the branch's parent" do
        @new_root = stateless('dad')
        
        assert_raises RuntimeError do
           Apotomo::StatefulWidget.thaw_for(@controller, @storage, @new_root)
        end
      end
      
      should "clear the fields in the storage when fetching in #thaw_for" do
        @new_root = stateless('root')
          @new_root << stateless('berry')
        
        Apotomo::StatefulWidget.thaw_for(@controller, @storage, @new_root)
        
        assert_nil @storage[:apotomo_stateful_branches]
        assert_nil @storage[:apotomo_widget_ivars]
      end
    end
    
    should "update @mum's ivars when calling #thaw_ivars_from" do
      @mum.instance_variable_set(:@name, "zombie mum")
      assert_equal 'zombie mum', @mum.name
      
      @mum.thaw_ivars_from({'zombie mum' => {'@name' => 'mum'}})
      assert_equal 'mum', @mum.name
    end
    
    should "update family's ivars when calling #thaw_data_from" do
      @kid << @pet = mouse_mock('pet')
      @kid.instance_variable_set(:@name, "paranoid kid")
      @pet.instance_variable_set(:@name, "mad dog")
      assert_equal "paranoid kid", @kid.name
      
      @mum.thaw_data_from({ "mum/paranoid kid"  => {'@name' => 'kid'},
                            "mum/kid/mad dog"   => {'@name' => 'pet'}})
      assert_equal 'kid', @kid.name
      assert_equal 'pet', @pet.name
    end
    
    
  end
  
  context "#dump_tree" do
    setup do
      @mum = stateful('mum')
      @mum << @kid = stateful('kid')
        @kid << @pet = stateful('pet')
      @mum << @berry = stateful('berry')
      
    end
    
    should "return a list of widget metadata" do
      assert_equal [[PersistentMouse, 'mum', nil], [PersistentMouse, 'kid', 'mum'], [PersistentMouse, 'pet', 'kid'], [PersistentMouse, 'berry', 'mum']], @mum.dump_tree
    end
    
    should "return a tree for #load_tree" do
      cold_widgets = @mum.dump_tree
      assert_equal ['mum', 'kid', 'pet', 'berry'], Apotomo::StatefulWidget.send(:load_tree, @controller, cold_widgets).collect { |n| n.name }
    end
    
    context "#frozen_widget_in?" do
      should "return true if a valid widget is passed" do
        @session = {}
        assert_not Apotomo::StatefulWidget.frozen_widget_in?(@session)
        Apotomo::StatefulWidget.freeze_for(@session, @berry)
        assert Apotomo::StatefulWidget.frozen_widget_in?(@session)
      end
    end
  end
  
  
  
  context "#symbolized_instance_variables?" do
    should "return instance_variables as symbols" do
      @mum = mouse_mock
      assert_equal @mum.instance_variables.size, @mum.symbolized_instance_variables.size
      assert_not @mum.symbolized_instance_variables.find { |ivar| ivar.kind_of? String }
    end
  end
end
