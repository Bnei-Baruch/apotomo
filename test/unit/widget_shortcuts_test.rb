require 'test_helper'

class MumWidget < MouseCell; end
class MouseTabs;end

class WidgetShortcutsTest < Test::Unit::TestCase
  include Apotomo::TestCaseMethods::TestController
  
  context "#constant_for" do
    should "constantize symbols" do
      assert_equal MumWidget, constant_for(:mum_widget)
    end
    
    should "not try to singularize the widget class" do
      assert_equal MouseTabs, constant_for(:mouse_tabs)
    end
  end
  
  context "#cell" do
    should "create a MouseCell instance for backward-compatibility" do
      assert_kind_of MouseCell, cell(:mouse, :eating, 'mum')
    end
  end
  
  context "#widget" do   
    context "with all arguments" do
      setup do
        @mum = widget(:mum_widget, 'mum', :eating, :color => 'grey', :type => :hungry)
      end
      
      should "create a MumWidget instance" do
        assert_kind_of MumWidget, @mum
        assert_equal :eating, @mum.instance_variable_get(:@start_state)
        assert_equal 'mum', @mum.name
      end
      
      should "accept options" do
        assert_equal({:color => "grey", :type => :hungry}, @mum.opts)
      end
    end
    
    context "with 3 arguments and no start_state" do
      should "set a default start_state" do
        @mum = widget(:mum_widget, 'mum', :color => 'grey', :type => :hungry)
        assert_kind_of MumWidget, @mum
        assert_equal :display,  @mum.instance_variable_get(:@start_state)
        assert_equal 'mum',     @mum.name
        assert_equal({:color => "grey", :type => :hungry}, @mum.opts)
      end
    end
    
    context "with 3 arguments and no options" do
      should "not set options" do
        @mum = widget(:mum_widget, 'mum', :squeak)
        assert_kind_of MumWidget, @mum
        assert_equal :squeak,   @mum.instance_variable_get(:@start_state)
        assert_equal 'mum',     @mum.name
        assert_equal({},        @mum.opts)
      end
    end
    
    context "with id only" do
      setup do
        @mum = widget(:mum_widget, 'mum')
      end
      
      should "create a MumWidget instance with :display start state" do
        assert_kind_of MumWidget, @mum
        assert_equal :display, @mum.instance_variable_get(:@start_state)
        assert_equal 'mum', @mum.name
      end
    end
    
    should "yield itself" do
      @mum = widget(:mum_widget, :snuggle, 'mum') do |mum|
        assert_kind_of MumWidget, mum
        mum << widget(:mum_widget, 'kid', :sleep)
      end
      assert_equal 2, @mum.size
      assert_kind_of MumWidget, @mum['kid']
    end
  end
  
  context "#container" do
    setup do
      @family = container('family')
    end
    
    should "create a ContainerWidget instance" do
      assert_kind_of ::Apotomo::ContainerWidget, @family
      assert_equal 'family', @family.name
    end
    
    should "yield itself" do
      @container = container(:family) do |family|
        family << widget(:mum_widget, 'mum')
      end
      assert_equal 2, @container.size
    end
    
    should "be aliased to #section for backward-compatibility" do
      assert_kind_of ::Apotomo::ContainerWidget, section('family')
    end
  end
end
