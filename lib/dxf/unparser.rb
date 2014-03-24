require 'geometry'
require 'sketch'
require 'units'
require 'stringio'

module DXF
	class Unparser
		attr_accessor :container
		
		# Initialize with a Sketch
		# @param [String,Symbol] units	The units to convert length values to (:inches or :millimeters)
		def initialize(units=:mm)
			@units = units
		end
		
		def to_s
			io = StringIO.new
			unparse(io, container)
			io.string
		end
	
	# @group Element Formatters
		# Convert a {Geometry::Line} into group codes
		def line(first, last, layer=0, transformation=nil, options={})
			first, last = Geometry::Point[first], Geometry::Point[last]
			first, last = [first, last].map {|point| transformation.transform(point) } if transformation
			
			[ 0, 'LINE',
			8, layer,
			10, format_value(first.x),
			20, format_value(first.y),
			11, format_value(last.x),
			21, format_value(last.y) ]
		end
	# @endgroup
		
		def text(position, content, layer=0, transformation=nil)
			position = transformation.transform(position) if transformation
			
			[ 0, 'TEXT',
			8, layer,
			10, format_value(position.x),
			20, format_value(position.y),
			1, content,
			7, 'NewTextStyle_4' ]
		end
	
	# @group Property Converters
		# Convert the given value to the correct units and return it as a formatted string
		# @return [String]
		def format_value(value)
			if value.is_a? Units::Numeric
				"%g" % value.send("to_#{@units}".to_sym)
			else
				"%g" % value
			end
		end
		
		def setOptions(options={})
			group_code = []
			group_code.concat [62, options[:color]] if options[:color]
			group_code.concat [6, 'DASHED'] if options[:dashed]
			group_code
		end
		
		# Emit the group codes for the center property of an element
		# @param [Point] point	The center point to format
		def center(point, transformation, options={})
			point = transformation.transform(point) if transformation
			[ 10, format_value(point.x), 20, format_value(point.y) ]
		end
		
		# Emit the group codes for the radius property of an element
		def radius(element, transformation=nil)
			[ 40, format_value(transformation ? transformation.transform(element.radius) : element.radius) ]
		end
		
		def section_end
			[ 0, 'ENDSEC' ]
		end
		
		def section_start(name)
			[0, 'SECTION', 2, name]
		end
		
		def table_start(name)
			[0, 'TABLE', 2, name]
		end
		
		def table_end
			[0, 'ENDTAB']
		end
		
		def ltype(name)
			table_entry = [100, 'AcDbLinetypeTableRecord']
			if name == 'dashed'
				[2, 'LTYPE', 0, 'LTYPE', 2, 'DASHED', 73, 1]
				# table_entry.concat([49, 0.5])
			end
		end
	# @endgroup

		# Convert an element to an Array
		# @param [Transformation] transformation    The transformation to apply to each geometry element
		# @return [Array]
		def to_array(element, transformation=nil)
			layer = 0;
			case element
				when Geometry::Arc
					[ 0, 'ARC', center(element.center, transformation), radius(element),
					50, format_value(element.start_angle),
					51, format_value(element.end_angle)].concat setOptions(element.options)
				when Geometry::Circle
					[0, 'CIRCLE', 8, layer, center(element.center, transformation), radius(element)]
				when Geometry::Text
					text(element.position, element.content, layer)
				when Geometry::Edge, Geometry::Line
					line(element.first, element.last, layer, transformation).concat setOptions(element.options)
				when Geometry::Polyline
					element.edges.map {|edge| line(edge.first, edge.last, layer, transformation).concat setOptions(element.options) }
				when Geometry::Rectangle
					element.edges.map {|edge| line(edge.first, edge.last, layer, transformation).concat setOptions(element.options) }
				when Geometry::Square
					points = element.points
					points.each_cons(2).map {|p1,p2| line(p1,p2, layer, transformation).concat setOptions(element.options) } + line(points.last, points.first, layer, transformation).concat setOptions(element.options)
				when Sketch
					transformation = transformation ? (transformation + element.transformation) : element.transformation
					element.geometry.map {|e| to_array(e, transformation)}
			end
		end

		# Convert a {Sketch} to a DXF file and write it to the given output
		# @param [IO] output    A writable IO-like object
		# @param [Sketch] sketch	The {Sketch} to unparse
		def unparse(output, sketch)
			output << (section_start('HEADER') + section_end +
			section_start('TABLES') +
				table_start('LTYPE') + ltype('dashed') + table_end +
			section_end +
			section_start('ENTITIES') + to_array(sketch) + section_end +
			[0, 'EOF']).join("\n")
		end
    end
end