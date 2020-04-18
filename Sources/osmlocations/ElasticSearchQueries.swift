let elasticShapeQuery = """
{
    "from": %d,
    "size": %d,
	"query": {
		"bool": {
			"must": {
				"match_all": {}
			},
			"filter": {
				"geo_shape": {
					"osmshape": {
						"relation": "%@",
						"shape": {
							"type": "envelope",
							"coordinates": [ [%lf, %lf], [%lf, %lf] ]
						}
					}
				}
			}
		}
	}
}
"""
