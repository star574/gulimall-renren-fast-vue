<template>
 <el-tree
      ref="tree"
      :data="data"
      :props="defaultProps"
      node-key="catId"
    >
 </el-tree>
</template>

<script>
export default {
  data() {
    return {
      /* 所有需要修改的节点 */
      data: [],
      expandedKey: [],
      defaultProps: {
        children: 'children',
        label: 'name'
      }
    }
  },
  created() {
    this.getCategoryList()
  },
  methods: {
    /* 获取树形列表 */
    getCategoryList(info = '') {
      this.loading = true
      this.$http({
        url: this.$http.adornUrl(`/product/category/list/tree/${info}`),
        method: 'get'
      }).then((result) => {
        this.data = result.data.categoryServiceList
        this.loading = false
      }).catch((err) => {
        console.log(err)
      })
    }
  }
}
</script>

<style>

</style>
