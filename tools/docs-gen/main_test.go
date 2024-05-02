package main

import (
	"reflect"
	"testing"
)

func TestDecodeNatspec(t *testing.T) {
	cases := []struct {
		str  string
		spec *natSpec
	}{

		{
			`@notice Calculate tree age in years, rounded up, for live trees
@return value is the random number`,
			&natSpec{
				Description: "Calculate tree age in years, rounded up, for live trees",
				Param:       []*natValue{},
				Return: []*natValue{
					{Name: "value", Description: "is the random number"},
				},
			},
		},
		{
			`@notice Calculate tree age in years, rounded up, for live trees
@param a is the first value
@param b is the second value
@return c is the first return value`,
			&natSpec{
				Description: "Calculate tree age in years, rounded up, for live trees",
				Param: []*natValue{
					{Name: "a", Description: "is the first value"},
					{Name: "b", Description: "is the second value"},
				},
				Return: []*natValue{
					{Name: "c", Description: "is the fist return value"},
				},
			},
		},
	}

	for _, c := range cases {
		t.Run("", func(t *testing.T) {
			spec, err := parseNatSpec(c.str)
			if err != nil {
				t.Fatal(err)
			}
			if !reflect.DeepEqual(spec, c.spec) {
				t.Fatal("not equal")
			}
		})
	}
}
