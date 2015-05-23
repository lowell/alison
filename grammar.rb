#!/usr/bin/env ruby

# Started as a translation of https://github.com/swift2js/swift2js/blob/master/grammar_scrapper/parse.js

require 'rubygems'
require 'nokogiri'

def parseRuleList(list)
	list.map do |node|
		value = { :optional => false, :literal => false }

		if node['class'] == 'optional'
			node = node.children.first
			value[:optional] = true
		end

		if node['class'] == 'syntactic-cat'
			value[:literal] = false
			value[:title] = node.children.first.inner_text.strip
		end

		if node['class'] == 'literal'
			value[:literal] = true
			value[:title] = node.inner_text[0...-1]
		end

		value unless value[:title].nil?
	end.compact
end

def parseSections(page)
	chapter = page.css('.chapter')
	
	chapter.xpath('//section').to_a.map do |section|
		defs = section.css('.syntax-defs')
		next if defs.count == 0

		{
			:title => section.css('.section-name').inner_text.strip,
			:groups => parseSyntaxGroups(defs)
		}
	end.compact
end

def parseSyntaxGroups(defs)
	defs.map do |group|
		{
			:title => group.css('.syntax-defs-name').inner_text.strip,
			:rules => group.css('.syntax-def').map { |rule| parseSyntaxRule(rule) }
		}
	end
end

def parseSyntaxRule(definition)
	rule = {
		:left => definition.css('.syntax-def-name').inner_text.strip,
		:alternatives => []
	}

	alts = definition.css('.alternative')

	alts.each do |alt|
		rule[:alternatives] << parseRuleList(alt.children)
	end

	if alts.count == 0
		children = definition.children
		arrow = children.select { |child| child['class'] == 'arrow' }.first
		children.slice(children.index(arrow) + 1) if arrow
		rule[:alternatives] << parseRuleList(children)
	end

	rule	
end

page = Nokogiri::HTML(File.read('grammar.html'))
sections = parseSections(page)
p sections
