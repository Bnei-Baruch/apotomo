require 'test_helper'

class WidgetTest < ActiveSupport::TestCase
  include Apotomo::TestCaseMethods::TestController
  
  context "The constructor" do
    should "accept the parent_controller as first arg" do
      assert_kind_of ActionController::Base, @controller
      @mum = Apotomo::Widget.new(@controller, 'mum', :squeak)
    end
  end
  
  context "Widget.has_widgets" do
    setup do
      @mum = Class.new(MouseCell) do
        has_widgets do |me|
          me << widget('mouse_cell', 'baby', :squeak)
        end
      end.new(@controller, 'mum', :squeak)
      
      @kid = Class.new(@mum.class).new(@controller, 'mum', :squeak)
    end
    
    should "setup the widget family at creation time" do
      assert_equal 1, @mum.children.size
      assert_kind_of Apotomo::StatefulWidget, @mum['baby']
    end
    
    should "inherit trees for now" do
      assert_equal 1, @mum.children.size
      assert_kind_of Apotomo::StatefulWidget, @mum['baby']
    end
  end
  
  context "Widget.after_add" do
    setup do
      @mum = Class.new(MouseCell) do
        after_add do |me, parent|
          parent << widget('mouse_cell', 'kid', :squeak)
        end
      end.new(@controller, 'mum', :squeak)
      
      @root = mouse_mock('root')
    end
    
    should "be invoked after mum is added" do
      assert_equal [], @root.children
      @root << @mum
      
      assert_equal ['mum', 'kid'], @root.children.collect { |w| w.name }
    end
    
    should "inherit callbacks for now" do
      @berry = Class.new(@mum.class).new(@controller, 'berry', :squeak)
      @root << @berry
      
      assert_equal ['berry', 'kid'], @root.children.collect { |w| w.name }
    end
  end
  
  context "A stateless widget" do
    setup do
      @mum = Apotomo::Widget.new(@controller, 'mum', :squeak)
    end
    
    context "responding to #address_for_event" do
      should "accept an event :type" do
        assert_equal({:source=>"mum", :type=>:squeak, :controller=>"barn"}, @mum.address_for_event(:squeak))
      end
      
      should "accept a :source" do
        assert_equal({:source=>"kid", :type=>:squeak, :controller=>"barn"}, @mum.address_for_event(:squeak, :source => 'kid'))
      end
      
      should "accept arbitrary options" do
        assert_equal({:volume=>"loud", :source=>"mum", :type=>:squeak, :controller=>"barn"}, @mum.address_for_event(:squeak, :volume => 'loud'))
      end
    end
    
    context "implementing visibility" do
      should "per default respond to #visible?" do
        assert @mum.visible?
      end
      
      should "expose a setter therefore" do
        @mum.visible = false
        assert_not @mum.visible?
      end
      
      context "in a widget family" do
        setup do
          @mum << @jerry = mouse_mock('jerry')
          @mum << @berry = mouse_mock('berry')
        end
        
        should "per default return all #visible_children" do
          assert_equal [@jerry, @berry], @mum.visible_children
          assert_equal [], @jerry.visible_children
        end
        
        should "hide berry in #visible_children if he's invisible" do
          @berry.visible = false
          assert_equal [@jerry], @mum.visible_children
        end
      end
    end
    
    should "respond to #find_widget" do
      mum_and_kid!
      assert_not @mum.find_widget('pet')
      assert_equal @kid, @mum.find_widget('kid')
    end
    
    should "respond to the WidgetShortcuts methods, like #widget" do
      assert_respond_to @mum, :widget
    end
    
    should "respond to #parent_controller" do
      assert_equal @controller, @mum.parent_controller
    end
    
    should "alias #widget_id to #name" do
      assert_equal @mum.name, @mum.widget_id
    end
    
    should "provide #param" do
      @controller.params = HashWithIndifferentAccess.new('type' => 'Wireless mouse', :brand => "Logitech")
      @mum = widget(:mouse_cell, 'mum', :display, :color => 'grey', :type => 'shrew')
      assert_equal nil,     @mum.param(:whatever)
      assert_equal 'grey',  @mum.param(:color)
      assert_equal 'grey',  @mum.param('color')
      assert_equal 'shrew', @mum.param(:type)
      assert_equal 'Logitech', @mum.param(:brand)
    end
  end
end
