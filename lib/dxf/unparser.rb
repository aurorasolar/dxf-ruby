require 'geometry'
require 'sketch'
require 'units'
require 'stringio'

# constants
METRIC = 'metric'
FEET_CODE = 2
METERS_CODE = 6

module DXF
    class Unparser
        attr_accessor :container

        # Initialize with a Sketch
        # @param [Number] precison	number of decimal places to keep for the practional component
        def initialize(precision = 4)
            @precision = precision
        end

        def to_s
            io = StringIO.new
            unparse(io, container)
            io.string
        end

    # @group Element Formatters
        # Convert a {Geometry::Line} into group codes
        def line(first, last, layer=1, transformation=nil, options={})
            first, last = Geometry::Point[first], Geometry::Point[last]
            first, last = [first, last].map {|point| transformation.transform(point) } if transformation

            [
                0, 'LINE',
                8, layer,
                10, format_value(first.x),
                20, format_value(first.y),
                11, format_value(last.x),
                21, format_value(last.y)
            ]
        end
    # @endgroup

        def pline(points, layer=1, transformation=nil, options={})

            points = points.map {|point| transformation.transform(point) } if transformation

            # {
            #   0: 'AcDb2dPolyline' (group code)
      #   8: [layer]          (layer)
            #   70: 1               (close polyline)
      #   39: 1               (thickness)
            # }
            code = [
                0, 'LWPOLYLINE',
                8, layer,
                90, points.length,
            ]

            # {
            #   10: [x] (x coordinate of a point)
            #   20: [y] (y coordinate of a point)
            # }
            for point in points
                code.push 10
                code.push point.x
                code.push 20
                code.push point.y
            end

            code
        end

        def text(position, content, layer=1, transformation=nil)
            position = transformation.transform(position) if transformation

            [
                0, 'TEXT',
                8, layer, # 'E-TEXT'
                100, 'AcDbText',
                10, format_value(position.x),
                20, format_value(position.y),
                1, content,
                7, 'NewTextStyle_4'
            ]
        end

        def hatch(vertices, layer=1)
            xs = []
            ys = []

            # populate array of x coordinates & array of y coordinates
            for vertex in vertices
                xs.push format_value(vertex.x)
                ys.push format_value(vertex.y)
            end

            [
                0, 'HATCH',
                8, layer,
                100, 'AcDbHatch',
                70, 0,
                91, 1,
                92, 2,
                8, layer,
                93, vertices.length, # number of polyline vertices
                10, xs,
                20, ys
            ]
        end

    # @group Property Converters
        # Rounds value
        # @return [String]
        def format_value(value)
            "%.#{@precision}f" % value
        end

        # Emit the group codes for the center property of an element
        # @param [Point] point  The center point to format
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

        def section_start(name, content = [])
            [0, 'SECTION', 2, name]
        end

        def section_code(name, content = [])
            section_start(name) + content + section_end
        end

        def table_start(name)
            [0, 'TABLE', 2, name]
        end

        def table_end
            [0, 'ENDTAB']
        end

        def ltype(name)
            table_entry = [100, 'AcDbLinetypeTableRecord']
            table_entry += [2, 'LTYPE', 0, 'LTYPE', 2, 'DASHED', 70, 0, 3, 'dashed line', 72, 65, 73, 2, 40, '4.0', 49, '2.0', 49, '-2.0'] if name == 'dashed'
            #   table_entry.concat [2, 'LTYPE', 0, 'LTYPE', 2, 'DASHED', 73, 1]
            #   # table_entry.concat([49, 0.5])
            # end
            table_entry
        end

        def set_options(options={})
            group_code = []
            group_code += [62, options[:color]] if options[:color]
            group_code += [6, 'DASHED'] if options[:dashed]
            group_code += [40, options[:lineHeight]] if options[:lineHeight]
            group_code += [39, options[:thickness]] if options[:thickness]
            group_code += [50, options[:rotation]] if options[:rotation]
            group_code += [70, 1] if options[:closed]
            group_code
        end

        def set_layers(layers)
            table_group = [70, layers.count]
            for layer in layers
                table_group += [0, 'LAYER', 100, 'AcDbSymbolTable', 100, 'AcDbLayerTable', 2, layer, 70, 0, 62, 7, 6, 'CONTINUOUS']
            end
            table_group
        end
    # @endgroup

        # Convert an element to an Array
        # @param [Transformation] transformation    The transformation to apply to each geometry element
        # @return [Array]
        def to_array(element, transformation=nil)
            layer = 1
            layer = element.options[:layer] if element.class != Sketch and element.options[:layer]
            case element
                when Geometry::Arc
                    [0, 'ARC', 8, layer, center(element.center, transformation), radius(element),
                    50, format_value(element.start_angle),
                    51, format_value(element.end_angle)] + set_options(element.options)
                when Geometry::Circle
                    [0, 'CIRCLE', 8, layer, center(element.center, transformation), radius(element)] + set_options(element.options)
                when Geometry::Text
                    text(element.position, element.content, layer) + set_options(element.options)
                when Geometry::Edge, Geometry::Line
                    line(element.first, element.last, layer, transformation) + set_options(element.options)
                when Geometry::Polyline
                    # return hatch(element.vertices, layer) if element.options[:hatch]
                    element.edges.map {|edge| line(edge.first, edge.last, layer, transformation) + set_options(element.options) }
                    # pline(element.vertices, layer, transformation) + set_options(element.options)
                when Geometry::Rectangle
                    element.edges.map {|edge| line(edge.first, edge.last, layer, transformation) + set_options(element.options) }
                    # pline(element.points, layer, transformation) + set_options(element.options)
                when Geometry::Square
                    points = element.points
                    points.each_cons(2).map {|p1,p2| line(p1,p2, layer, transformation) + set_options(element.options) } + line(points.last, points.first, layer, transformation) + set_options(element.options)
                when Sketch
                    transformation = transformation ? (transformation + element.transformation) : element.transformation
                    element.geometry.map {|e| to_array(e, transformation)}
            end
        end

        def unit_code(units)
            units == METRIC ? METERS_CODE : FEET_CODE
        end

        def title_code
            start = [999, 'Design created by Aurora']
        end

        def header_code(units = METRIC)
            section_code('HEADER', [
                9, '$ACADVER',
                1, 'AC1009',
                9, '$INSUNITS',
                70, unit_code(units)
            ])
        end

        def table_code(layers)
            section_code('TABLES',
                table_start('LTYPE') +
                ltype('dashed') +
                table_end +
                table_start('LAYER') +
                set_layers(layers) +
                table_end
            )
        end

        def entity_code(sketch)
            section_code('ENTITIES', to_array(sketch))
        end

        def eof
          [0, 'EOF']
        end

        # Convert a {Sketch} to a DXF file and write it to the given output
        # @param [IO] output    A writable IO-like object
        # @param [Sketch] sketch    The {Sketch} to unparse
        def unparse(sketch, layers=[1], units)
            (
                title_code +
                header_code(units) +
                table_code(layers) +
                entity_code(sketch) +
                eof
            ).join("\r\n")
        end
    end
end
