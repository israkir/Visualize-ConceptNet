# Copyright (c) 2012, Chi-En Wu
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the organization nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

String.format = (str) ->
    if arguments.length == 0
        return null

    args = Array.prototype.slice.call(arguments, 1)
    str.replace(/\{(\d+)\}/g, (m, i) -> args[i])

calculateDistance = (d, maxScore) ->
    80 + 50 * Math.log(if d.target.score? then (maxScore - d.target.score) / maxScore + 1 else 1)

class Graph
    constructor: (canvas) ->
        @canvas = d3.select(canvas)
        @force = d3.layout.force()
            .charge(-2000)
            .size([@width(), @height()])

        d3.select(window).on("resize", =>
            @force.size([@width(), @height()])
            return
        )

    width: ->
        parseInt(@canvas.style("width"), 10)

    height: ->
        parseInt(@canvas.style("height"), 10)

    load: (lang, term) ->
        url = String.format("/c/{0}/{1}", lang, term)
        d3.json(url, (json) =>
            @root = json
            @update()
        )
        return

    update: ->
        root = @root
        root.fixed = true
        root.x = @width() / 2
        root.y = @height() / 2

        # push nodes and links
        nodes = [root]
        links = []
        root.children.forEach (rel) ->
            nodes.push(rel)
            links.push
                source: root
                target: rel
            rel.children.forEach (target) ->
                nodes.push(target)
                links.push
                    source: rel
                    target: target

        # restart the force layout
        @force
            .nodes(nodes)
            .links(links)
            .linkDistance((d) -> calculateDistance(d, root.maxScore))
            .start()

        # update the links
        svgLinks = @canvas.selectAll("line.link").data(links)

        # create new links
        svgLinks.enter().insert("line", ".node")
            .attr("class", "link")

        # remove unnecessary links
        svgLinks.exit().remove()

        # update the nodes
        svgNodes = @canvas.selectAll("g.node").data(nodes)

        # create new nodes
        svgNodes.enter().append("g")
            .attr("class", (d) -> "node " + d.type)
            .call(@force.drag)

        svgNodes.append("circle")
            .attr("r", 30)

        svgNodes.append("text")
            .attr("dy", ".31em")
            .attr("text-anchor", "middle")
            .text((d) -> if d.name.length > 8 then d.name.substr(0, 6) + "..." else d.name)

        svgNodes.append("title")
            .text((d) -> d.name)

        # remove unnecessary nodes
        svgNodes.exit().remove()

        # register the tick event handler
        @force.on("tick", ->
            svgLinks
                .attr("x1", (d) -> d.source.x)
                .attr("y1", (d) -> d.source.y)
                .attr("x2", (d) -> d.target.x)
                .attr("y2", (d) -> d.target.y)
            svgNodes
                .attr("transform", (d) -> "translate(" + d.x + "," + d.y + ")")
            return
        )
        return

# export functions
window.Graph = Graph
